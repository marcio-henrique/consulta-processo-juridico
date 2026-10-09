module Types
  class QueryType < Types::BaseObject
    field :me, Types::UserType, null: true, description: "Current user or null."

    field :lawsuit, Types::LawsuitPayloadType, null: false,
      description: "Find a lawsuit by CNJ number (formatted or digits-only)." do
      argument :number, String, required: true
    end

    def me
      Resolvers::MeResolver.call(context: context)
    end

    def lawsuit(number:)
      Resolvers::LawsuitResolver.call(number: number, context: context)
    end
  end
end
