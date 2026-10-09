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

    def value
      { amount: MoneyFormatter.amount(object.value), formatted: MoneyFormatter.format(object.value) }
    end

    def movements_count
      dataloader.with(Sources::MovementsCount).load(object.id)
    end

    # Query.lawsuit validates the arguments up front (UserError in the payload);
    # this is the safety net for any other path that reaches the field.
    def movements(first: nil, after: nil)
      first ||= Lawsuits::MovementsPage::DEFAULT_SIZE
      if Lawsuits::MovementsPage.invalid_argument(first: first, after: after)
        raise GraphQL::ExecutionError, Errors::Messages::INVALID_ARGUMENT
      end

      page = Lawsuits::MovementsPage.call(object, first: first, after: after)
      {
        nodes: page.nodes,
        page_info: {
          has_next_page: page.has_next_page,
          has_previous_page: page.has_previous_page,
          start_cursor: page.start_cursor,
          end_cursor: page.end_cursor
        }
      }
    end

    def latest_summary
      raise NotImplementedError, "implemented in spec 04"
    end
  end
end
