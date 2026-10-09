module Types
  class LawsuitType < Types::BaseObject
    graphql_name "Lawsuit"

    field :number, String, null: false,
      description: "Canonical CNJ number, for example 1001399-31.2023.8.26.0070."
    field :forum, String, null: false
    field :court, String, null: false
    field :value, Types::MoneyType, null: false
    field :number_of_authors, Integer, null: false
    field :movements_count, Integer, null: false
    field :movements, Types::MovementConnectionType, null: false,
      connection: false,
      description: "Newest first: occurred_on DESC, then source_row ASC. first defaults to 25, max 100." do
      argument :first, Integer, required: false, default_value: 25
      argument :after, String, required: false
    end
    field :latest_summary, Types::SummaryType, null: true,
      description: "Cached summary for the current movements and prompt version. Never calls the LLM."

    def movements(first:, after:)
      raise NotImplementedError, "implemented in spec 03"
    end

    def latest_summary
      raise NotImplementedError, "implemented in spec 04"
    end
  end
end
