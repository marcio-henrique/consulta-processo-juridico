require "rails_helper"

RSpec.describe "Health check", type: :request do
  it "GET /up returns 200 when the app and DB are ready" do
    get "/up"

    expect(response).to have_http_status(:ok)
  end
end
