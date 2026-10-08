module Types
  class LawsuitPayloadType < Types::BaseObject
    graphql_name "LawsuitPayload"

    field :lawsuit, Types::LawsuitType, null: true
    field :errors, [ Types::UserErrorType ], null: false
  end
end
