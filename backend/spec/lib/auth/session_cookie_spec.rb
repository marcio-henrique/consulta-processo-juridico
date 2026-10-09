require "rails_helper"

RSpec.describe Auth::SessionCookie do
  it "uses the documented cookie name" do
    expect(described_class::NAME).to eq(:_lawsuit_session)
  end

  describe ".options" do
    it "is HttpOnly, SameSite=Lax, Path=/ and expires with the session" do
      expires_at = 14.days.from_now
      options = described_class.options("raw", expires_at: expires_at, secure: false)

      expect(options).to include(value: "raw", httponly: true, same_site: :lax, path: "/", secure: false, expires: expires_at)
    end

    it "is Secure in production" do
      allow(Rails.env).to receive(:production?).and_return(true)
      expect(described_class.options("raw", expires_at: 1.day.from_now)[:secure]).to be(true)
    end

    it "is not Secure outside production, so http://localhost works" do
      expect(described_class.options("raw", expires_at: 1.day.from_now)[:secure]).to be(false)
    end
  end
end
