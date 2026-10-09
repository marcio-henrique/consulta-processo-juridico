require "rails_helper"

RSpec.describe Session do
  it "is valid from the factory" do
    expect(build(:session)).to be_valid
  end

  it "keeps the 14 day lifetime in one place" do
    expect(described_class::LIFETIME).to eq(14.days)
  end

  describe ".active" do
    it "returns only sessions that have not expired" do
      live = create(:session, expires_at: 1.minute.from_now)
      create(:session, expires_at: 1.minute.ago)
      expect(described_class.active).to contain_exactly(live)
    end
  end

  describe "#expired?" do
    it "is true once expires_at has passed" do
      expect(build(:session, expires_at: 1.second.ago)).to be_expired
      expect(build(:session, expires_at: 1.hour.from_now)).not_to be_expired
    end
  end

  describe ".digest" do
    it "delegates to Auth::SessionToken" do
      expect(described_class.digest("abc")).to eq(Auth::SessionToken.digest("abc"))
    end
  end

  it "is deleted with its user" do
    session = create(:session)
    expect { session.user.destroy }.to change(described_class, :count).by(-1)
  end
end
