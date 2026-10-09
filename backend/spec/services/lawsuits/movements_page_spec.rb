require "rails_helper"

RSpec.describe Lawsuits::MovementsPage do
  describe ".invalid_argument" do
    it "accepts first within 1..100 and a well-formed cursor" do
      expect(described_class.invalid_argument(first: 1)).to be_nil
      expect(described_class.invalid_argument(first: 100, after: described_class.encode(3))).to be_nil
    end

    it "flags first outside the range or not an integer" do
      [ 0, -5, 101, nil, "10" ].each do |value|
        expect(described_class.invalid_argument(first: value)).to eq("first"), "expected #{value.inspect} to be invalid"
      end
    end

    it "flags malformed cursors" do
      [ "garbage", "%%%", Base64.urlsafe_encode64("x:1"), Base64.urlsafe_encode64("o:-1") ].each do |cursor|
        expect(described_class.invalid_argument(first: 10, after: cursor)).to eq("after")
      end
    end
  end

  describe ".encode / .decode" do
    it "round-trips positions" do
      expect(described_class.decode(described_class.encode(42))).to eq(42)
    end
  end

  describe ".call" do
    let(:lawsuit) { create(:lawsuit) }

    it "returns an empty page for a lawsuit without movements" do
      page = described_class.call(lawsuit)
      expect(page.nodes).to eq([])
      expect(page.has_next_page).to be(false)
      expect(page.start_cursor).to be_nil
      expect(page.end_cursor).to be_nil
    end

    it "rejects invalid arguments" do
      expect { described_class.call(lawsuit, first: 0) }.to raise_error(ArgumentError)
    end
  end
end
