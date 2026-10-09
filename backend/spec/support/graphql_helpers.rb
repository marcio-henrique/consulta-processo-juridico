module GraphqlHelpers
  # Executes a GraphQL query/mutation directly against BackendSchema, bypassing
  # the HTTP layer (faster, and lets specs assert on the parsed result hash).
  #
  # user: :default (the default) builds a factory user and authenticates as
  # them; pass a User to run as that user, or `user: nil` to run as an
  # anonymous visitor (see spec 06: every operation except signUp, signIn and
  # me requires a signed-in user).
  def execute_graphql(query, variables: {}, user: :default)
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
