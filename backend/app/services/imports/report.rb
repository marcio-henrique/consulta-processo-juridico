module Imports
  # Counters and row-level findings of one import run (data-import.md section 6).
  class Report
    Entry = Struct.new(:line, :message)

    attr_accessor :lawsuits_created, :lawsuits_updated, :lawsuits_unchanged,
                  :movements_inserted, :movements_deleted, :duration
    attr_reader :skipped, :warnings

    def initialize
      @lawsuits_created = @lawsuits_updated = @lawsuits_unchanged = 0
      @movements_inserted = @movements_deleted = 0
      @duration = 0.0
      @skipped = []
      @warnings = []
    end

    def skip(line:, reason:)
      skipped << Entry.new(line, reason)
    end

    def warn(line:, message:)
      warnings << Entry.new(line, message)
    end

    def rows_skipped
      skipped.size
    end

    def to_s
      lines = [
        "Import finished in #{format('%.1f', duration)}s",
        "Lawsuits: #{lawsuits_created} created, #{lawsuits_updated} updated, #{lawsuits_unchanged} unchanged",
        "Movements: #{movements_inserted} inserted, #{movements_deleted} deleted",
        "Rows skipped: #{rows_skipped}",
        "Warnings: #{warnings.size}"
      ]
      skipped.each { |entry| lines << "  skipped line #{entry.line}: #{entry.message}" }
      warnings.each { |entry| lines << "  warning line #{entry.line}: #{entry.message}" }
      lines.join("\n")
    end
  end
end
