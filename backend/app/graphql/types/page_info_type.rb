module Types
  class PageInfoType < Types::BaseObject
    graphql_name "PageInfo"

    field :has_next_page, Boolean, null: false
    field :has_previous_page, Boolean, null: false
    field :start_cursor, String, null: true
    field :end_cursor, String, null: true
  end
end
