module Mutations
  # Mutation.rateSummary: upserts the signed-in user's vote on a summary.
  # Anonymous callers never get here (schema guard, UNAUTHENTICATED).
  class RateSummary
    def self.call(summary_id:, helpful:, context:)
      result = Feedback::Rate.call(user: context[:current_user], summary_id: summary_id, helpful: helpful)
      return { feedback: result.feedback, errors: [] } if result.success?

      code = result.error_code
      { feedback: nil, errors: [ Errors::Messages.build(code.to_s, Errors::Messages.for(code)) ] }
    end
  end
end
