module Feedback
  # Aggregates votes per prompt version and model, to compare prompts/models.
  # Only counts are printed: never user ids, emails or summary text.
  class Report
    HEADERS = %w[prompt_version model summaries votes helpful not_helpful helpful_rate].freeze
    NO_VOTES_MESSAGE = "No feedback votes yet.".freeze

    Row = Struct.new(:prompt_version, :model, :summaries, :votes, :helpful, :not_helpful, keyword_init: true) do
      def helpful_rate
        votes.zero? ? "-" : format("%.1f%%", helpful * 100.0 / votes)
      end
    end

    def self.call
      new.to_s
    end

    def rows
      @rows ||= query.map do |record|
        Row.new(
          prompt_version: record.prompt_version, model: record.model,
          summaries: record.summaries.to_i, votes: record.votes.to_i,
          helpful: record.helpful.to_i, not_helpful: record.not_helpful.to_i
        )
      end
    end

    def to_s
      return NO_VOTES_MESSAGE if rows.sum(&:votes).zero?

      table = [ HEADERS ] + rows.map do |row|
        [ row.prompt_version, row.model, row.summaries, row.votes, row.helpful, row.not_helpful, row.helpful_rate ].map(&:to_s)
      end
      widths = HEADERS.each_index.map { |i| table.map { |line| line[i].length }.max }
      table.map { |line| line.each_with_index.map { |cell, i| cell.ljust(widths[i]) }.join("  ").rstrip }.join("\n")
    end

    private

    # Left join keeps summaries that nobody voted on in the summaries count.
    def query
      Summary
        .left_joins(:summary_feedbacks)
        .group(:prompt_version, :model)
        .order(:prompt_version, :model)
        .select(
          "summaries.prompt_version, summaries.model",
          "COUNT(DISTINCT summaries.id) AS summaries",
          "COUNT(summary_feedbacks.id) AS votes",
          "COUNT(summary_feedbacks.id) FILTER (WHERE summary_feedbacks.helpful) AS helpful",
          "COUNT(summary_feedbacks.id) FILTER (WHERE NOT summary_feedbacks.helpful) AS not_helpful"
        )
    end
  end
end
