require "rails_helper"

RSpec.describe "Log hygiene", type: :request do
  PASSWORD = "S3cret-passphrase-for-log-test".freeze
  FAKE_KEY = "AIza-FAKE-KEY-for-log-test-0123".freeze

  def capture_log
    io = StringIO.new
    broadcast = ActiveSupport::Logger.new(io)
    Rails.logger.broadcast_to(broadcast)
    yield
    io.string
  ensure
    Rails.logger.stop_broadcasting_to(broadcast)
  end

  def post_graphql(query, variables = {})
    post "/graphql",
      params: { query: query, variables: variables }.to_json,
      headers: { "CONTENT_TYPE" => "application/json", "HTTP_AUTHORIZATION" => "Bearer header-secret-value" }
  end

  it "never logs passwords, GraphQL variables, cookies or authorization headers" do
    mutation = "mutation($i: SignUpInput!) { signUp(input: $i) { errors { code } } }"
    cookie_value = nil
    log = capture_log do
      post_graphql(mutation, { i: { email: "logtest@example.com", password: PASSWORD } })
      cookie_value = cookies["_lawsuit_session"]
      post_graphql("{ me { id } }") # sends the session cookie back
    end

    expect(cookie_value).to be_present
    expect(log).to include("Processing by GraphqlController#execute") # the log was really captured
    expect(log).not_to include(PASSWORD)
    expect(log).not_to include("logtest@example.com")
    expect(log).not_to include(cookie_value)
    expect(log).not_to include("header-secret-value")
    expect(log).to include("[FILTERED]")
  end

  it "does not log the query text, which could carry inline literals" do
    log = capture_log do
      post_graphql(%(mutation { signIn(input: {email: "inline@example.com", password: "#{PASSWORD}"}) { errors { code } } }))
    end

    expect(log).not_to include(PASSWORD)
    expect(log).not_to include("inline@example.com")
  end

  it "does not leak the Gemini key when the provider fails" do
    url = %r{generativelanguage\.googleapis\.com}
    stub_request(:post, url).to_return(status: 500, body: "boom")
    provider = Llm::Providers::Gemini.new(api_key: FAKE_KEY)
    error = nil

    log = capture_log do
      begin
        provider.complete(model: "m", system: "s", user: "u", max_output_tokens: 10, timeout: 2)
      rescue StandardError => e
        error = e
        Rails.logger.error("provider failed: #{e.class}: #{e.message}")
      end
    end

    expect(error).to be_present
    expect(error.message).not_to include(FAKE_KEY)
    expect(provider.inspect).not_to include(FAKE_KEY)
    expect(log).not_to include(FAKE_KEY)
  end

  it "configures the documented filter list" do
    filters = Rails.application.config.filter_parameters.map(&:to_s)
    %w[passw token authorization secret cookie variables query].each do |name|
      expect(filters).to include(a_string_matching(name)), "#{name} is not filtered"
    end
  end
end
