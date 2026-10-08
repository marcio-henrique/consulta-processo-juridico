module Types
  class QueryType < Types::BaseObject
    # Placeholder field so the schema is valid before spec 03 adds the real
    # `lawsuit` and `me` fields.
    field :version, String, null: false,
      description: "API version string, used to prove the GraphQL endpoint is wired up."

    def version
      "0.1.0"
    end
  end
end
