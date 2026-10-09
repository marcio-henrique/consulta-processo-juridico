require "rails_helper"

RSpec.describe Auth::SignIn do
  let!(:user) { create(:user, email: "ana@example.com", password: "a-very-safe-password") }

  def call(email: "ana@example.com", password: "a-very-safe-password")
    described_class.call(email: email, password: password, user_agent: "RSpec", ip_address: "10.0.0.1")
  end

  it "creates a new session for matching credentials" do
    result = nil
    expect { result = call }.to change(Session, :count).by(1)

    expect(result).to be_success
    expect(result.user).to eq(user)
    expect(Session.last.token_digest).to eq(Auth::SessionToken.digest(result.token))
  end

  it "ignores case and surrounding spaces in the email" do
    expect(call(email: "  ANA@Example.com ")).to be_success
  end

  it "gives wrong password and unknown email the same error" do
    wrong_password = call(password: "another-password-1")
    unknown_email = call(email: "nobody@example.com")
    expected = [ { code: "UNAUTHENTICATED", message: "E-mail ou senha inválidos.", field: nil } ]

    expect(wrong_password.errors).to eq(expected)
    expect(unknown_email.errors).to eq(expected)
    expect(wrong_password.token).to be_nil
    expect(Session.count).to eq(0)
  end

  it "still runs a bcrypt comparison for unknown emails (comparable time)" do
    allow(BCrypt::Password).to receive(:new).and_call_original
    call(email: "nobody@example.com")
    expect(BCrypt::Password).to have_received(:new).with(described_class::DUMMY_DIGEST)
  end

  it "does not blow up on nil input" do
    expect(call(email: nil, password: nil)).not_to be_success
  end
end
