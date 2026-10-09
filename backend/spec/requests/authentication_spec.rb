require "rails_helper"

RSpec.describe "Authentication over HTTP", type: :request do
  SIGN_UP = <<~GQL
    mutation($input: SignUpInput!) { signUp(input: $input) { user { id email } errors { code message field } } }
  GQL
  SIGN_IN = <<~GQL
    mutation($input: SignInInput!) { signIn(input: $input) { user { id email } errors { code message field } } }
  GQL
  SIGN_OUT = "mutation { signOut { success errors { code message } } }"
  ME = "{ me { id email } }"
  LAWSUIT = 'query { lawsuit(number: "1001399-31.2023.8.26.0070") { lawsuit { number } errors { code } } }'

  def gql(query, variables = {}, headers: {})
    post "/graphql",
      params: { query: query, variables: variables }.to_json,
      headers: { "CONTENT_TYPE" => "application/json" }.merge(headers)
    JSON.parse(response.body)
  end

  def session_cookie_header
    Array(response.headers["Set-Cookie"]).join("\n")[/_lawsuit_session=[^\n]*/]
  end

  let(:credentials) { { email: "ana@example.com", password: "a-very-safe-password" } }

  describe "signUp" do
    it "creates the account, starts a session and sets a hardened cookie" do
      body = gql(SIGN_UP, { input: credentials })

      expect(body.dig("data", "signUp", "user", "email")).to eq("ana@example.com")
      expect(body.dig("data", "signUp", "errors")).to eq([])
      cookie = session_cookie_header
      expect(cookie).to match(/httponly/i)
      expect(cookie).to match(/samesite=lax/i)
      expect(cookie).to match(%r{path=/}i)
      expect(cookie).to match(/expires=/i)
      expect(cookie).not_to match(/;\s*secure/i) # Secure only in production
      raw = cookie[/_lawsuit_session=([^;]+)/, 1]
      expect(Session.find_by(token_digest: Auth::SessionToken.digest(raw))).to be_present
    end

    it "returns validation errors with the field and sets no cookie" do
      body = gql(SIGN_UP, { input: { email: "nope", password: "short" } })

      expect(body.dig("data", "signUp", "user")).to be_nil
      expect(body.dig("data", "signUp", "errors").map { |e| [ e["code"], e["field"] ] })
        .to contain_exactly([ "VALIDATION_FAILED", "email" ], [ "VALIDATION_FAILED", "password" ])
      expect(session_cookie_header).to be_nil
    end
  end

  describe "me and the session cookie" do
    it "is null for anonymous visitors" do
      expect(gql(ME).dig("data", "me")).to be_nil
    end

    it "returns the current user after signing up (cookie jar reused)" do
      gql(SIGN_UP, { input: credentials })
      expect(gql(ME).dig("data", "me", "email")).to eq("ana@example.com")
    end

    it "treats an expired session as anonymous" do
      gql(SIGN_UP, { input: credentials })
      Session.update_all(expires_at: 1.minute.ago)
      expect(gql(ME).dig("data", "me")).to be_nil
    end

    it "treats a forged or unknown cookie as anonymous" do
      cookies["_lawsuit_session"] = "forged-token"
      expect(gql(ME).dig("data", "me")).to be_nil
    end
  end

  describe "signIn" do
    before { create(:user, **credentials) }

    it "starts a session and sets the cookie" do
      body = gql(SIGN_IN, { input: credentials })

      expect(body.dig("data", "signIn", "user", "email")).to eq("ana@example.com")
      expect(session_cookie_header).to match(/httponly/i)
      expect(gql(ME).dig("data", "me", "email")).to eq("ana@example.com")
    end

    it "returns the same generic error for a wrong password and an unknown email" do
      wrong = gql(SIGN_IN, { input: credentials.merge(password: "wrong-password-1") })
      unknown = gql(SIGN_IN, { input: { email: "nobody@example.com", password: "whatever-password" } })

      [ wrong, unknown ].each do |body|
        expect(body.dig("data", "signIn", "user")).to be_nil
        expect(body.dig("data", "signIn", "errors")).to eq([
          { "code" => "UNAUTHENTICATED", "message" => "E-mail ou senha inválidos.", "field" => nil }
        ])
      end
      expect(session_cookie_header).to be_nil
    end

    it "replaces the current session instead of piling up sessions" do
      gql(SIGN_IN, { input: credentials })
      expect { gql(SIGN_IN, { input: credentials }) }.not_to change(Session, :count)
    end
  end

  describe "signOut" do
    it "deletes the session row, clears the cookie and makes the old cookie useless" do
      gql(SIGN_UP, { input: credentials })
      old_cookie = cookies["_lawsuit_session"]

      body = gql(SIGN_OUT)

      expect(body.dig("data", "signOut", "success")).to be(true)
      expect(Session.count).to eq(0)
      expect(session_cookie_header).to match(/_lawsuit_session=;|max-age=0|expires=Thu, 01 Jan 1970/i)
      cookies["_lawsuit_session"] = old_cookie
      expect(gql(ME).dig("data", "me")).to be_nil
    end

    it "is rejected for anonymous visitors" do
      body = gql(SIGN_OUT)
      expect(body.dig("data", "signOut", "success")).to be(false)
      expect(body.dig("data", "signOut", "errors", 0, "code")).to eq("UNAUTHENTICATED")
    end
  end

  describe "protected operations" do
    it "answers lawsuit with UNAUTHENTICATED (HTTP 200) for anonymous visitors" do
      create(:lawsuit, number: "1001399-31.2023.8.26.0070")
      body = gql(LAWSUIT)

      expect(response).to have_http_status(:ok)
      expect(body.dig("data", "lawsuit", "lawsuit")).to be_nil
      expect(body.dig("data", "lawsuit", "errors", 0)).to eq("code" => "UNAUTHENTICATED")
    end

    it "serves the lawsuit once signed in" do
      create(:lawsuit, number: "1001399-31.2023.8.26.0070")
      gql(SIGN_UP, { input: credentials })
      expect(gql(LAWSUIT).dig("data", "lawsuit", "lawsuit", "number")).to eq("1001399-31.2023.8.26.0070")
    end
  end

  describe "request protection" do
    it "rejects a request whose Origin host differs from the request host with 403" do
      post "/graphql",
        params: { query: ME }.to_json,
        headers: { "CONTENT_TYPE" => "application/json", "HTTP_ORIGIN" => "https://evil.example" }
      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "accepts a request whose Origin host matches the request host" do
      post "/graphql",
        params: { query: ME }.to_json,
        headers: { "CONTENT_TYPE" => "application/json", "HTTP_ORIGIN" => "http://www.example.com" }
      expect(response).to have_http_status(:ok)
    end

    it "rejects a malformed Origin with 403" do
      post "/graphql",
        params: { query: ME }.to_json,
        headers: { "CONTENT_TYPE" => "application/json", "HTTP_ORIGIN" => "http://exa mple" }
      expect(response).to have_http_status(:forbidden)
    end

    it "rejects text/plain with 415 and GET with 405" do
      post "/graphql", params: ME, headers: { "CONTENT_TYPE" => "text/plain" }
      expect(response).to have_http_status(:unsupported_media_type)
      get "/graphql"
      expect(response).to have_http_status(:method_not_allowed)
    end
  end
end
