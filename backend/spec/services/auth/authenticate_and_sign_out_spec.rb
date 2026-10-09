require "rails_helper"

RSpec.describe "Auth::Authenticate and Auth::SignOut" do
  let(:user) { create(:user) }

  def session_with_token(**attrs)
    raw, digest = Auth::SessionToken.generate
    [ raw, create(:session, user: user, token_digest: digest, **attrs) ]
  end

  describe Auth::Authenticate do
    it "returns the session for a valid token" do
      raw, session = session_with_token
      expect(described_class.call(raw)).to eq(session)
    end

    it "returns nil for blank, unknown or malformed tokens" do
      expect(described_class.call(nil)).to be_nil
      expect(described_class.call("")).to be_nil
      expect(described_class.call("unknown")).to be_nil
    end

    it "rejects an expired session and purges it lazily" do
      raw, session = session_with_token(expires_at: 1.minute.ago)
      expect(described_class.call(raw)).to be_nil
      expect(Session.exists?(session.id)).to be(false)
    end
  end

  describe Auth::SignOut do
    it "deletes the session row" do
      raw, session = session_with_token
      expect { described_class.call(session) }.to change(Session, :count).by(-1)
      expect(Auth::Authenticate.call(raw)).to be_nil
    end

    it "is a no-op for nil" do
      expect { described_class.call(nil) }.not_to raise_error
    end
  end
end
