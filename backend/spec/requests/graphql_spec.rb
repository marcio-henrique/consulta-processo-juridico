require "rails_helper"

RSpec.describe "POST /graphql", type: :request do
  it "returns 200 and executes the query for a JSON POST" do
    post "/graphql",
      params: { query: "{ version }" }.to_json,
      headers: { "CONTENT_TYPE" => "application/json" }

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body.dig("data", "version")).to be_a(String)
  end

  it "returns 405 for a GET request" do
    get "/graphql"

    expect(response).to have_http_status(:method_not_allowed)
  end

  it "returns 415 for a non-JSON content type" do
    post "/graphql",
      params: "query={ version }",
      headers: { "CONTENT_TYPE" => "application/x-www-form-urlencoded" }

    expect(response).to have_http_status(:unsupported_media_type)
  end
end
