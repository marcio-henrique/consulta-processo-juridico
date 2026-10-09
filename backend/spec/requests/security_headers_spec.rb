require "rails_helper"

RSpec.describe "Security headers", type: :request do
  CSP = "default-src 'self'; script-src 'self'; object-src 'none'; frame-ancestors 'none'; base-uri 'self'".freeze

  def expect_hardened_headers
    expect(response.headers["Content-Security-Policy"]).to eq(CSP)
    expect(response.headers["X-Content-Type-Options"]).to eq("nosniff")
    expect(response.headers["Referrer-Policy"]).to eq("same-origin")
    expect(response.headers["X-Frame-Options"]).to eq("DENY")
  end

  it "is set on /up" do
    get "/up"
    expect_hardened_headers
  end

  it "is set on /graphql, including error responses" do
    post "/graphql", params: { query: "{ __typename }" }.to_json, headers: { "CONTENT_TYPE" => "application/json" }
    expect_hardened_headers

    get "/graphql"
    expect(response).to have_http_status(:method_not_allowed)
    expect_hardened_headers

    post "/graphql", params: "x", headers: { "CONTENT_TYPE" => "text/plain" }
    expect(response).to have_http_status(:unsupported_media_type)
    expect_hardened_headers
  end

  it "is set on unknown routes too" do
    get "/nothing-here"
    expect_hardened_headers
  end

  it "sends HSTS only in production" do
    get "/up"
    expect(response.headers).not_to have_key("Strict-Transport-Security")
  end

  describe SecurityHeaders do
    def call(env_name)
      app = ->(_env) { [ 200, {}, [ "ok" ] ] }
      described_class.new(app, rails_env: ActiveSupport::StringInquirer.new(env_name)).call({})[1]
    end

    it "adds HSTS in production" do
      expect(call("production")["Strict-Transport-Security"]).to match(/max-age=\d+; includeSubDomains/)
    end

    it "overrides looser values set downstream" do
      app = ->(_env) { [ 200, { "Referrer-Policy" => "no-referrer-when-downgrade" }, [] ] }
      headers = described_class.new(app, rails_env: ActiveSupport::StringInquirer.new("test")).call({})[1]
      expect(headers["Referrer-Policy"]).to eq("same-origin")
    end
  end
end
