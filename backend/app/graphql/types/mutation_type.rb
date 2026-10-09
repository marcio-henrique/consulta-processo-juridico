module Types
  class MutationType < Types::BaseObject
    field :sign_up, Types::AuthPayloadType, null: false do
      argument :input, Types::SignUpInputType, required: true
    end

    field :sign_in, Types::AuthPayloadType, null: false do
      argument :input, Types::SignInInputType, required: true
    end

    field :sign_out, Types::SignOutPayloadType, null: false

    field :generate_summary, Types::GenerateSummaryPayloadType, null: false,
      description: "Returns the cached summary or generates one synchronously (see ADR-0003)." do
      argument :lawsuit_number, String, required: true
    end

    field :rate_summary, Types::RateSummaryPayloadType, null: false,
      description: "Upsert the current user's vote for a summary." do
      argument :summary_id, ID, required: true
      argument :helpful, Boolean, required: true
    end

    def sign_up(input:)
      Mutations::SignUp.call(input: input, context: context)
    end

    def sign_in(input:)
      Mutations::SignIn.call(input: input, context: context)
    end

    def sign_out
      Mutations::SignOut.call(context: context)
    end

    def generate_summary(lawsuit_number:)
      Mutations::GenerateSummary.call(lawsuit_number: lawsuit_number, context: context)
    end

    def rate_summary(summary_id:, helpful:)
      Mutations::RateSummary.call(summary_id: summary_id, helpful: helpful, context: context)
    end
  end
end
