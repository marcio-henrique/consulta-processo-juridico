module Feedback
  # Records the user's vote on a summary. One row per (summary, user): voting
  # again overwrites the vote, so the call is idempotent. The upsert relies on
  # the unique index, so concurrent clicks cannot raise or duplicate rows.
  #
  #   Feedback::Rate.call(user: user, summary_id: "12", helpful: true)
  class Rate
    Result = Struct.new(:feedback, :error_code, keyword_init: true) do
      def success?
        error_code.nil?
      end
    end

    def self.call(user:, summary_id:, helpful:)
      new(user, summary_id, helpful).call
    end

    def initialize(user, summary_id, helpful)
      @user = user
      @summary_id = summary_id
      @helpful = helpful
    end

    def call
      summary = find_summary
      return Result.new(error_code: :NOT_FOUND) if summary.nil?

      SummaryFeedback.upsert(
        { summary_id: summary.id, user_id: @user.id, helpful: @helpful },
        unique_by: [ :summary_id, :user_id ]
      )
      Result.new(feedback: SummaryFeedback.find_by!(summary_id: summary.id, user_id: @user.id))
    end

    private

    def find_summary
      id = Integer(@summary_id.to_s, 10, exception: false)
      id && Summary.find_by(id: id)
    rescue ActiveModel::RangeError
      nil
    end
  end
end
