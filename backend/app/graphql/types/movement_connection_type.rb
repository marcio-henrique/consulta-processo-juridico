module Types
  class MovementConnectionType < Types::BaseObject
    graphql_name "MovementConnection"

    field :nodes, [ Types::MovementType ], null: false
    field :page_info, Types::PageInfoType, null: false
  end
end
