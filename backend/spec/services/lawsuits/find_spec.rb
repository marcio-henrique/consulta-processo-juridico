require "rails_helper"

RSpec.describe Lawsuits::Find do
  let!(:lawsuit) { create(:lawsuit, number: "1001399-31.2023.8.26.0070") }

  it "finds by the canonical number" do
    result = described_class.call("1001399-31.2023.8.26.0070")
    expect(result.lawsuit).to eq(lawsuit)
    expect(result.error_code).to be_nil
    expect(result).to be_success
  end

  it "finds by digits only" do
    expect(described_class.call("10013993120238260070").lawsuit).to eq(lawsuit)
  end

  it "ignores surrounding whitespace" do
    expect(described_class.call("  1001399-31.2023.8.26.0070\n").lawsuit).to eq(lawsuit)
  end

  it "returns INVALID_CNJ for a bad check digit" do
    result = described_class.call("1001399-31.2023.8.26.0071")
    expect(result.lawsuit).to be_nil
    expect(result.error_code).to eq(:INVALID_CNJ)
    expect(result).not_to be_success
  end

  it "returns INVALID_CNJ for malformed input" do
    [ "", "abc", "123", "1" * 21, nil ].each do |raw|
      expect(described_class.call(raw).error_code).to eq(:INVALID_CNJ), "expected #{raw.inspect} to be invalid"
    end
  end

  it "returns NOT_FOUND for a valid number that is not stored" do
    result = described_class.call("1002271-82.2025.8.26.0003")
    expect(result.lawsuit).to be_nil
    expect(result.error_code).to eq(:NOT_FOUND)
  end

  it "does not match by prefix or substring" do
    expect(described_class.call("1001399").error_code).to eq(:INVALID_CNJ)
    expect(described_class.call("1001399-31.2023.8.26").error_code).to eq(:INVALID_CNJ)
  end
end
