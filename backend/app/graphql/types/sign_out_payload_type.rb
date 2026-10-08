module Types
  class SignOutPayloadType < Types::BaseObject
    graphql_name "SignOutPayload"

    field :success, Boolean, null: false
    field :errors, [ Types::UserErrorType ], null: false
  end
end
