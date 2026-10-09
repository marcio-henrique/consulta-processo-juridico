module Types
  class MovementType < Types::BaseObject
    graphql_name "Movement"

    field :id, ID, null: false
    field :date, GraphQL::Types::ISO8601Date, null: false, method: :occurred_on
    field :title, String, null: false
    field :content, String, null: true,
      description: "Plain text, may contain line breaks. Null when the court gave no content."
  end
end
