module Types
  class AuthPayloadType < Types::BaseObject
    graphql_name "AuthPayload"

    field :user, Types::UserType, null: true
    field :errors, [ Types::UserErrorType ], null: false
  end
end
