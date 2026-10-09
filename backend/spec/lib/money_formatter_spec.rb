require "rails_helper"

RSpec.describe MoneyFormatter do
  describe ".amount" do
    it "returns a decimal string with two places" do
      expect(described_class.amount(BigDecimal("10000"))).to eq("10000.00")
      expect(described_class.amount(BigDecimal("10168.2"))).to eq("10168.20")
      expect(described_class.amount(0)).to eq("0.00")
    end
  end

  describe ".format" do
    it "formats whole values as pt-BR currency" do
      expect(described_class.format(BigDecimal("8000"))).to eq("R$ 8.000,00")
    end

    it "formats cents and thousands separators" do
      expect(described_class.format(BigDecimal("13028.16"))).to eq("R$ 13.028,16")
      expect(described_class.format(BigDecimal("7650.11"))).to eq("R$ 7.650,11")
    end

    it "formats zero and small values" do
      expect(described_class.format(0)).to eq("R$ 0,00")
      expect(described_class.format(BigDecimal("0.5"))).to eq("R$ 0,50")
    end

    it "formats millions" do
      expect(described_class.format(BigDecimal("1234567.89"))).to eq("R$ 1.234.567,89")
    end
  end
end
