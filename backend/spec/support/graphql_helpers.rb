module GraphqlHelpers
  # Executes a GraphQL query/mutation directly against BackendSchema, bypassing
  # the HTTP layer (faster, and lets specs assert on the parsed result hash).
  #
  # user: :default builds a factory user and authenticates as them (used by
  # specs that need `current_user` in context, see spec 06). nil (the
  # default) runs as an anonymous visitor.
  def execute_graphql(query, variables: {}, user: nil)
    current_user = (user == :default) ? FactoryBot.create(:user) : user

    result = BackendSchema.execute(
      query,
      variables: variables,
      context: { current_user: current_user }
    )

    result.to_h.deep_symbolize_keys
  end
end

RSpec.configure do |config|
  config.include GraphqlHelpers, type: :graphql
end
