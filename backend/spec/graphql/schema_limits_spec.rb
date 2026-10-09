require "rails_helper"

RSpec.describe "BackendSchema limits and error handling", type: :graphql do
  describe "depth limit" do
    it "is configured with a maximum depth of 10" do
      expect(BackendSchema.max_depth).to eq(10)
    end

    it "rejects queries deeper than the limit" do
      # Deep through introspection: __schema -> types -> fields -> type -> ofType chain.
      too_deep = "{ __schema { types { fields { type { ofType { ofType { ofType { ofType { ofType { ofType { name } } } } } } } } } } }"
      result = execute_graphql(too_deep)
      expect(result[:errors].first[:message]).to match(/exceeds max depth/)
    end
  end

  describe "complexity limit" do
    it "is configured explicitly" do
      expect(BackendSchema.max_complexity).to be_a(Integer).and be <= 200
    end
  end

  describe "unexpected errors" do
    it "returns a generic message, logs the error and hides internals" do
      allow(Lawsuits::Find).to receive(:call).and_raise(RuntimeError, "secret db detail")
      allow(Rails.logger).to receive(:error)

      result = execute_graphql('{ lawsuit(number: "1001399-31.2023.8.26.0070") { errors { code } } }')

      expect(result[:errors].first[:message]).to eq("Erro interno. Tente novamente.")
      expect(result.to_s).not_to include("secret db detail")
      expect(Rails.logger).to have_received(:error).with(/RuntimeError/)
    end

    it "includes the request id in the log line when present" do
      allow(Lawsuits::Find).to receive(:call).and_raise(RuntimeError, "boom")
      allow(Rails.logger).to receive(:error)

      BackendSchema.execute(
        '{ lawsuit(number: "1001399-31.2023.8.26.0070") { errors { code } } }',
        context: { current_user: create(:user), request_id: "req-123" }
      )

      expect(Rails.logger).to have_received(:error).with(/request_id=req-123/)
    end
  end
end
