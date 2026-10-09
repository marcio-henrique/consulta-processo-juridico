require "csv"

module Imports
  # Imports lawsuits and their movements from the challenge CSV.
  # Idempotent: per lawsuit, in one transaction, upsert the lawsuit and replace
  # its movements (only when they differ). See docs/domains/data-import.md and
  # ADR-0005.
  class LawsuitsCsv
    REQUIRED_HEADERS = %w[
      lawsuit_number lawsuit_forum lawsuit_court lawsuit_value lawsuit_number_of_authors
      movement_date movement_title movement_content
    ].freeze

    # CSV column for each lawsuit attribute (used in warnings).
    LAWSUIT_COLUMNS = {
      forum: "lawsuit_forum",
      court: "lawsuit_court",
      value: "lawsuit_value",
      number_of_authors: "lawsuit_number_of_authors"
    }.freeze

    MOVEMENT_FIELDS = %i[occurred_on title content source_row].freeze

    # A row-level problem: the row is skipped and reported.
    class RowError < StandardError; end

    ParsedRow = Struct.new(:line, :number, :attributes, :movement, keyword_init: true)

    def self.call(path = default_path)
      new(path).call
    end

    def self.default_path
      ENV["LAWSUITS_CSV_PATH"].presence || File.expand_path("../data/lawsuits_movements.csv", Rails.root)
    end

    def initialize(path)
      @path = path.to_s
      @report = Report.new
    end

    # @return [Imports::Report]
    # @raise [Imports::FatalError] when the file cannot be read as a lawsuits CSV
    def call
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      groups = read_groups
      groups.sort_by { |number, _rows| number }.each { |number, rows| import_lawsuit(number, rows) }
      report.duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
      report
    end

    private

    attr_reader :path, :report

    # --- Reading ---------------------------------------------------------

    def read_groups
      ensure_readable_file!
      groups = Hash.new { |hash, number| hash[number] = [] }
      each_record do |record, line, source_row|
        parsed = parse_row(record, line, source_row)
        groups[parsed.number] << parsed if parsed
      end
      groups
    end

    def ensure_readable_file!
      raise FatalError, "CSV path is blank" if path.blank?
      raise FatalError, "CSV file not found: #{path}" unless File.exist?(path)
      raise FatalError, "CSV path is not a readable file: #{path}" unless File.file?(path) && File.readable?(path)
    end

    # Yields (record, first physical line of the record, 1-based data-row index).
    # Quoted fields may span lines, so physical lines are tracked separately.
    def each_record
      File.open(path, "r:bom|utf-8") do |file|
        csv = CSV.new(file, headers: true, header_converters: ->(header) { header.to_s.strip })
        line = 1 # the header
        source_row = 0
        headers_checked = false
        while (record = csv.shift)
          validate_headers!(csv.headers) unless headers_checked
          headers_checked = true
          first_line = line + 1
          line += csv.line.lines.size
          next if record.fields.all?(&:blank?) # blank line

          source_row += 1
          yield record, first_line, source_row
        end
        validate_headers!(csv.headers) unless headers_checked
      end
    rescue CSV::InvalidEncodingError
      raise FatalError, "CSV file is not valid UTF-8: #{path}"
    rescue CSV::MalformedCSVError => e
      raise FatalError, "malformed CSV: #{e.message}"
    rescue SystemCallError => e
      raise FatalError, "cannot read CSV file #{path}: #{e.message}"
    end

    def validate_headers!(headers)
      raise FatalError, "CSV header row is missing: #{path}" unless headers.is_a?(Array)

      missing = REQUIRED_HEADERS - headers
      raise FatalError, "CSV is missing required header(s): #{missing.join(', ')}" if missing.any?
    end

    # --- Row parsing -----------------------------------------------------

    def parse_row(record, line, source_row)
      number = parse_number(record)
      attributes = {
        forum: required(record, "lawsuit_forum"),
        court: required(record, "lawsuit_court"),
        value: parse_field("lawsuit_value") { BrlParser.money(record["lawsuit_value"]) },
        number_of_authors: parse_authors(record)
      }
      movement = {
        occurred_on: parse_field("movement_date") { BrlParser.date(record["movement_date"]) },
        title: required(record, "movement_title"),
        content: normalize_content(record["movement_content"]),
        source_row: source_row
      }
      ParsedRow.new(line: line, number: number, attributes: attributes, movement: movement)
    rescue RowError => e
      report.skip(line: line, reason: e.message)
      nil
    end

    def parse_number(record)
      result = CnjNumber.parse(record["lawsuit_number"])
      raise RowError, "lawsuit_number: #{result.error.to_s.tr('_', ' ')}" unless result.valid?

      result.formatted
    end

    def parse_authors(record)
      raw = required(record, "lawsuit_number_of_authors")
      authors = Integer(raw, 10, exception: false)
      raise RowError, "lawsuit_number_of_authors: must be an integer >= 1, got #{raw.inspect}" if authors.nil? || authors < 1

      authors
    end

    def required(record, column)
      value = record[column].to_s.strip
      raise RowError, "#{column} is missing" if value.empty?

      value
    end

    def parse_field(column)
      yield
    rescue BrlParser::ParseError => e
      raise RowError, "#{column}: #{e.message}"
    end

    def normalize_content(raw)
      return nil if raw.nil? || raw.strip.empty?

      raw.gsub("\r\n", "\n")
    end

    # --- Persisting ------------------------------------------------------

    def import_lawsuit(number, rows)
      first = rows.first
      warn_conflicts(number, first, rows.drop(1))
      outcome = persist(number, first.attributes, rows.map(&:movement))
      record_outcome(outcome)
    rescue ActiveRecord::ActiveRecordError => e
      rows.each { |row| report.skip(line: row.line, reason: "lawsuit #{number} not imported: #{e.message}") }
    end

    def warn_conflicts(number, first, others)
      others.each do |row|
        differing = LAWSUIT_COLUMNS.select { |attribute, _| row.attributes[attribute] != first.attributes[attribute] }
        next if differing.empty?

        report.warn(
          line: row.line,
          message: "#{differing.values.join(', ')} differ(s) from the first row of #{number}; using the first row"
        )
      end
    end

    # One transaction per lawsuit. Returns a hash describing what changed;
    # the report is only touched after the commit.
    def persist(number, attributes, movements)
      Lawsuit.transaction do
        lawsuit = Lawsuit.find_or_initialize_by(number: number)
        created = lawsuit.new_record?
        lawsuit.assign_attributes(attributes)
        attributes_changed = lawsuit.changed?
        lawsuit.save! if attributes_changed

        deleted = inserted = 0
        if movements_differ?(lawsuit, movements)
          deleted = Movement.where(lawsuit_id: lawsuit.id).delete_all
          Movement.insert_all(movements.map { |movement| movement.merge(lawsuit_id: lawsuit.id) })
          inserted = movements.size
        end

        status = if created then :created
        elsif attributes_changed || inserted.positive? || deleted.positive? then :updated
        else :unchanged
        end
        { status: status, inserted: inserted, deleted: deleted }
      end
    end

    def movements_differ?(lawsuit, movements)
      stored = lawsuit.movements.order(:source_row).pluck(*MOVEMENT_FIELDS)
      wanted = movements.map { |movement| movement.values_at(*MOVEMENT_FIELDS) }
      stored != wanted
    end

    def record_outcome(outcome)
      case outcome[:status]
      when :created then report.lawsuits_created += 1
      when :updated then report.lawsuits_updated += 1
      else report.lawsuits_unchanged += 1
      end
      report.movements_inserted += outcome[:inserted]
      report.movements_deleted += outcome[:deleted]
    end
  end
end
