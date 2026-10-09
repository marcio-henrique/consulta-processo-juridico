module Types
  class SummaryFeedbackType < Types::BaseObject
    graphql_name "SummaryFeedback"

    field :summary_id, ID, null: false
    field :helpful, Boolean, null: false
  end
end
