require "rails_helper"

RSpec.describe "POST /graphql", type: :request do
  it "returns 200 and executes the query for a JSON POST" do
    post "/graphql",
      params: { query: "{ __typename }" }.to_json,
      headers: { "CONTENT_TYPE" => "application/json" }

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body.dig("data", "__typename")).to eq("Query")
  end

  it "serves the lawsuit query over HTTP, with expected failures as data" do
    create(:lawsuit, number: "1001399-31.2023.8.26.0070")
    query = 'query($n: String!) { lawsuit(number: $n) { lawsuit { number } errors { code } } }'

    post "/graphql",
      params: { query: query, variables: { n: "10013993120238260070" } }.to_json,
      headers: { "CONTENT_TYPE" => "application/json" }
    expect(JSON.parse(response.body).dig("data", "lawsuit", "lawsuit", "number")).to eq("1001399-31.2023.8.26.0070")

    post "/graphql",
      params: { query: query, variables: { n: "1002271-82.2025.8.26.0003" } }.to_json,
      headers: { "CONTENT_TYPE" => "application/json" }
    body = JSON.parse(response.body)
    expect(response).to have_http_status(:ok)
    expect(body["errors"]).to be_nil
    expect(body.dig("data", "lawsuit", "errors", 0, "code")).to eq("NOT_FOUND")
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
