require "rails_helper"

RSpec.describe Auth::SessionToken do
  describe ".generate" do
    it "returns a URL-safe raw token of 32 random bytes and its SHA-256 digest" do
      raw, digest = described_class.generate

      expect(raw).to match(/\A[A-Za-z0-9_-]{43}\z/) # 32 bytes, base64url without padding
      expect(Base64.urlsafe_decode64(raw).bytesize).to eq(32)
      expect(digest).to eq(Digest::SHA256.hexdigest(raw))
      expect(digest).not_to include(raw)
    end

    it "never repeats" do
      raws = Array.new(50) { described_class.generate.first }
      expect(raws.uniq.size).to eq(50)
    end
  end

  describe ".digest" do
    it "is deterministic and differs from the raw value" do
      expect(described_class.digest("abc")).to eq(described_class.digest("abc"))
      expect(described_class.digest("abc")).not_to eq("abc")
      expect(described_class.digest("abc")).to match(/\A\h{64}\z/)
    end

    it "treats nil as an empty token instead of raising" do
      expect(described_class.digest(nil)).to eq(Digest::SHA256.hexdigest(""))
    end
  end
end
