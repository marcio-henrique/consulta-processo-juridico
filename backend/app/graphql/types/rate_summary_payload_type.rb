module Types
  class RateSummaryPayloadType < Types::BaseObject
    graphql_name "RateSummaryPayload"

    field :feedback, Types::SummaryFeedbackType, null: true
    field :errors, [ Types::UserErrorType ], null: false
  end
end
