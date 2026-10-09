require "rails_helper"

RSpec.describe "GraphQL hardening (SEC-3)", type: :graphql do
  describe "alias flood" do
    def aliased(count, field: "__typename")
      "{ #{(1..count).map { |i| "a#{i}: #{field}" }.join(' ')} }"
    end

    it "allows up to 20 aliases of the same field" do
      result = execute_graphql(aliased(20))
      expect(result[:errors]).to be_nil
    end

    it "rejects more than 20 aliases of the same field" do
      result = execute_graphql(aliased(21))
      expect(result[:errors].first[:message]).to match(/too many aliases/i)
      expect(result[:data]).to be_nil
    end

    it "counts per field, so different fields do not add up" do
      query = "{ #{(1..15).map { |i| "a#{i}: __typename" }.join(' ')} #{(1..15).map { |i| "m#{i}: me { id }" }.join(' ')} }"
      expect(execute_graphql(query)[:errors]).to be_nil
    end
  end

  describe "complexity" do
    it "rejects queries above the configured cap" do
      schema = Class.new(BackendSchema) { max_complexity 3 }
      result = schema.execute('{ lawsuit(number: "1") { errors { code message field } } }',
        context: { current_user: create(:user) })
      expect(result.to_h["errors"].first["message"]).to match(/max complexity/)
    end
  end

  describe "page size" do
    it "rejects first above 100 as an INVALID_ARGUMENT user error" do
      create(:lawsuit, number: "1001399-31.2023.8.26.0070")
      result = execute_graphql('{ lawsuit(number: "1001399-31.2023.8.26.0070") { errors { code field } lawsuit { movements(first: 101) { nodes { id } } } } }')
      expect(result.dig(:data, :lawsuit, :errors, 0)).to include(code: "INVALID_ARGUMENT", field: "first")
    end
  end

  describe "introspection" do
    it "is enabled outside production" do
      expect(execute_graphql("{ __schema { queryType { name } } }")[:data]).to eq(__schema: { queryType: { name: "Query" } })
    end

    it "is disabled in production" do
      schema = Class.new(BackendSchema)
      Security::GraphqlLimits.apply(schema, rails_env: ActiveSupport::StringInquirer.new("production"))
      result = schema.execute("{ __schema { queryType { name } } }", context: { current_user: create(:user) })
      expect(result.to_h["errors"]).to be_present
      expect(result.to_h["data"]).to be_nil
    end
  end

  describe "error bodies" do
    it "does not leak internals when a resolver raises" do
      allow(Lawsuits::Find).to receive(:call).and_raise(RuntimeError, "pg password=hunter2")
      result = execute_graphql('{ lawsuit(number: "1001399-31.2023.8.26.0070") { errors { code } } }')
      expect(result.to_s).not_to include("hunter2")
      expect(result[:errors].first[:message]).to eq("Erro interno. Tente novamente.")
    end
  end
end
