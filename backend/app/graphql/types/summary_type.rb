module Types
  class SummaryType < Types::BaseObject
    graphql_name "Summary"

    field :id, ID, null: false
    field :body, String, null: false,
      description: "Plain text, at most 3 paragraphs separated by blank lines. Never HTML."
    field :generated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :my_feedback, Boolean, null: true,
      description: "Current user's vote: true, false or null (not voted). Never exposes other users."

    def my_feedback
      user = context[:current_user]
      return nil if user.nil?

      dataloader.with(Sources::MyFeedback, user.id).load(object.id)
    end
  end
end
