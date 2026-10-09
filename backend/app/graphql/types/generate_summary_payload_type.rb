module Types
  class GenerateSummaryPayloadType < Types::BaseObject
    graphql_name "GenerateSummaryPayload"

    field :summary, Types::SummaryType, null: true
    field :errors, [ Types::UserErrorType ], null: false
  end
end
