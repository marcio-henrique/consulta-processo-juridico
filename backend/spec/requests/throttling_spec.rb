require "rails_helper"

RSpec.describe "Throttling", type: :request do
  SIGN_IN_MUTATION = "mutation($i: SignInInput!) { signIn(input: $i) { errors { code message } } }".freeze
  SIGN_UP_MUTATION = "mutation($i: SignUpInput!) { signUp(input: $i) { errors { code message } } }".freeze
  GENERATE_MUTATION = <<~GQL.freeze
    mutation { generateSummary(lawsuitNumber: "1001399-31.2023.8.26.0070") { summary { id } errors { code message } } }
  GQL

  # Rack::Attack counts in fixed windows; pin the clock inside one window so a
  # minute boundary can never split an example.
  before { travel_to Time.zone.parse("2026-10-09 12:00:10") }
  after { travel_back }

  def gql(query, variables = {}, ip: "203.0.113.10")
    post "/graphql",
      params: { query: query, variables: variables }.to_json,
      headers: { "CONTENT_TYPE" => "application/json" },
      env: { "REMOTE_ADDR" => ip }
    JSON.parse(response.body)
  end

  def codes(body, field)
    body.dig("data", field, "errors").map { |e| e["code"] }
  end

  describe "signIn" do
    let(:attempt) { { i: { email: "ana@example.com", password: "wrong-password-1" } } }

    it "allows 5 attempts per minute per IP and limits the 6th with RATE_LIMITED" do
      5.times { |i| expect(codes(gql(SIGN_IN_MUTATION, { i: { email: "user#{i}@example.com", password: "x" } }), "signIn")).to eq([ "UNAUTHENTICATED" ]) }

      body = gql(SIGN_IN_MUTATION, attempt)
      expect(codes(body, "signIn")).to eq([ "RATE_LIMITED" ])
      expect(body.dig("data", "signIn", "errors", 0, "message")).to eq(Errors::Messages::RATE_LIMITED)
    end

    it "limits per email across different IPs, ignoring case" do
      5.times { |i| gql(SIGN_IN_MUTATION, { i: { email: "Ana@Example.com", password: "x" } }, ip: "198.51.100.#{i}") }

      body = gql(SIGN_IN_MUTATION, attempt, ip: "198.51.100.99")
      expect(codes(body, "signIn")).to eq([ "RATE_LIMITED" ])
    end

    it "does not check the password once limited, even if it is correct" do
      create(:user, email: "ana@example.com", password: "a-very-safe-password")
      5.times { gql(SIGN_IN_MUTATION, attempt) }

      body = gql(SIGN_IN_MUTATION, { i: { email: "ana@example.com", password: "a-very-safe-password" } })
      expect(codes(body, "signIn")).to eq([ "RATE_LIMITED" ])
      expect(response.headers["Set-Cookie"]).to be_nil
    end

    it "counts aliased attempts in one request, so aliases cannot bypass the limit" do
      aliases = (1..8).map { |i| %(a#{i}: signIn(input: {email: "x#{i}@example.com", password: "x"}) { errors { code } }) }
      body = gql("mutation { #{aliases.join(' ')} }")

      outcomes = (1..8).map { |i| body.dig("data", "a#{i}", "errors", 0, "code") }
      expect(outcomes.first(5)).to all(eq("UNAUTHENTICATED"))
      expect(outcomes.last(3)).to all(eq("RATE_LIMITED"))
    end

    it "starts over after the period" do
      5.times { gql(SIGN_IN_MUTATION, attempt) }
      travel_to Time.zone.parse("2026-10-09 12:01:10")
      expect(codes(gql(SIGN_IN_MUTATION, attempt), "signIn")).to eq([ "UNAUTHENTICATED" ])
    end
  end

  describe "signUp" do
    it "allows 10 sign-ups per hour per IP and limits the 11th" do
      10.times { |i| expect(codes(gql(SIGN_UP_MUTATION, { i: { email: "new#{i}@example.com", password: "a-very-safe-password" } }), "signUp")).to eq([]) }

      body = gql(SIGN_UP_MUTATION, { i: { email: "new11@example.com", password: "a-very-safe-password" } })
      expect(codes(body, "signUp")).to eq([ "RATE_LIMITED" ])
      expect(User.where(email: "new11@example.com")).to be_empty
    end

    it "does not limit another IP" do
      10.times { |i| gql(SIGN_UP_MUTATION, { i: { email: "new#{i}@example.com", password: "a-very-safe-password" } }) }
      body = gql(SIGN_UP_MUTATION, { i: { email: "other@example.com", password: "a-very-safe-password" } }, ip: "198.51.100.7")
      expect(codes(body, "signUp")).to eq([])
    end
  end

  describe "generateSummary" do
    before do
      create(:lawsuit, number: "1001399-31.2023.8.26.0070")
      gql(SIGN_UP_MUTATION, { i: { email: "ana@example.com", password: "a-very-safe-password" } })
    end

    it "allows 10 per minute per user and limits the 11th" do
      10.times { expect(codes(gql(GENERATE_MUTATION), "generateSummary")).to eq([]) }

      body = gql(GENERATE_MUTATION)
      expect(codes(body, "generateSummary")).to eq([ "RATE_LIMITED" ])
      expect(body.dig("data", "generateSummary", "errors", 0, "message")).to eq(Errors::Messages::RATE_LIMITED)
    end
  end

  describe "coarse per-IP limit on /graphql" do
    it "answers HTTP 429 with a pt-BR JSON error once an IP floods the endpoint" do
      limit = Rack::Attack.throttles["graphql/ip"].limit
      limit.times { post "/graphql", params: { query: "{ __typename }" }.to_json, headers: { "CONTENT_TYPE" => "application/json" } }
      expect(response).to have_http_status(:ok)

      post "/graphql", params: { query: "{ __typename }" }.to_json, headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:too_many_requests)
      expect(response.content_type).to start_with("application/json")
      expect(JSON.parse(response.body)["errors"].first).to include("code" => "RATE_LIMITED", "message" => Errors::Messages::RATE_LIMITED)
      expect(response.headers["Retry-After"]).to be_present
    end

    it "does not throttle /up" do
      (Rack::Attack.throttles["graphql/ip"].limit + 5).times { get "/up" }
      expect(response).to have_http_status(:ok)
    end
  end
end
