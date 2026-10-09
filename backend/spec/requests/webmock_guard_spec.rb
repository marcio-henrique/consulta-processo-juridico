require "rails_helper"

# Proves that real HTTP calls are blocked in the test environment, so a
# forgotten stub cannot silently hit a real (and possibly billed) endpoint
# such as the Gemini API. See AI-GUARDRAILS.md and ADR-0002.
RSpec.describe "WebMock guard", type: :request do
  it "blocks real outbound HTTP connections" do
    expect {
      Net::HTTP.get(URI("https://example.com"))
    }.to raise_error(WebMock::NetConnectNotAllowedError)
  end
end
