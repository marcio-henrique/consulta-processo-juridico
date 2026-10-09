require "rails_helper"

RSpec.describe Auth::SignUp do
  def call(email: "ana@example.com", password: "a-very-safe-password")
    described_class.call(email: email, password: password, user_agent: "RSpec", ip_address: "10.0.0.1")
  end

  it "creates the user and a session, returning the raw token once" do
    result = nil
    expect { result = call }.to change(User, :count).by(1).and change(Session, :count).by(1)

    expect(result).to be_success
    expect(result.user.email).to eq("ana@example.com")
    session = Session.last
    expect(session.token_digest).to eq(Auth::SessionToken.digest(result.token))
    expect(session.token_digest).not_to eq(result.token)
    expect(session.user_agent).to eq("RSpec")
    expect(session.ip_address).to eq("10.0.0.1")
    expect(session.expires_at).to be_within(1.minute).of(14.days.from_now)
  end

  it "reports a taken email as VALIDATION_FAILED on the email field" do
    create(:user, email: "ana@example.com")
    result = call(email: "ANA@example.com")

    expect(result).not_to be_success
    expect(result.errors).to eq([
      { code: "VALIDATION_FAILED", message: Errors::Messages::EMAIL_TAKEN, field: "email" }
    ])
    expect(Session.count).to eq(0)
  end

  it "reports an invalid email" do
    expect(call(email: "nope").errors).to eq([
      { code: "VALIDATION_FAILED", message: Errors::Messages::INVALID_EMAIL, field: "email" }
    ])
  end

  it "reports a short or too long password on the password field" do
    [ "short", "a" * 73 ].each do |password|
      expect(call(password: password).errors).to eq([
        { code: "VALIDATION_FAILED", message: Errors::Messages::INVALID_PASSWORD_LENGTH, field: "password" }
      ])
    end
  end

  it "reports both fields when both are invalid" do
    fields = call(email: "nope", password: "short").errors.map { |e| e[:field] }
    expect(fields).to contain_exactly("email", "password")
  end

  it "turns a unique-index race into the email-taken error" do
    allow_any_instance_of(User).to receive(:save).and_raise(ActiveRecord::RecordNotUnique)
    expect(call.errors.first).to include(field: "email", message: Errors::Messages::EMAIL_TAKEN)
  end
end
