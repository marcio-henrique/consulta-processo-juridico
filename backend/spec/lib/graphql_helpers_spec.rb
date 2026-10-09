require "rails_helper"

RSpec.describe "GraphqlHelpers#execute_graphql" do
  include GraphqlHelpers

  it "executes a query against BackendSchema and returns a symbolized hash" do
    result = execute_graphql("{ __typename }", user: nil)

    expect(result[:data][:__typename]).to eq("Query")
  end

  it "builds and authenticates a :default user" do
    expect {
      execute_graphql("{ __typename }", user: :default)
    }.to change(User, :count).by(1)
  end
end
