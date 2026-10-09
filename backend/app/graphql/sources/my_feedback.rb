module Sources
  # Batches the current user's votes for many summaries into one query.
  # Keyed by user, so the result can never contain another user's vote.
  # Returns true, false or nil (not voted) per summary id.
  class MyFeedback < GraphQL::Dataloader::Source
    def initialize(user_id)
      @user_id = user_id
    end

    def fetch(summary_ids)
      votes = SummaryFeedback.where(user_id: @user_id, summary_id: summary_ids).pluck(:summary_id, :helpful).to_h
      summary_ids.map { |id| votes[id] }
    end
  end
end
