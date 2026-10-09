module Types
  class UserErrorType < Types::BaseObject
    graphql_name "UserError"

    field :code, Types::ErrorCode, null: false
    field :message, String, null: false, description: "pt-BR, safe to show to users."
    field :field, String, null: true,
      description: "Input field name when the error is about one field (for example email, password, number)."
  end
end
