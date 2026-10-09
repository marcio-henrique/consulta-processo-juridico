require "rails_helper"

RSpec.describe BrlParser do
  describe ".money" do
    {
      "10.000" => "10000.00",
      "13.028,16" => "13028.16",
      "10.168,2" => "10168.20",
      "7.650,11" => "7650.11",
      "0" => "0.00",
      "999,99" => "999.99",
      " 2.423,06 " => "2423.06"
    }.each do |raw, expected|
      it "parses #{raw.inspect} as #{expected} (R2.1)" do
        result = described_class.money(raw)

        expect(result).to be_a(BigDecimal)
        expect(result).to eq(BigDecimal(expected))
      end
    end

    [ nil, "", "   ", "-10.000", "abc", "10,5,3", "1.0a", "R$ 10,00", "10,", ",50" ].each do |raw|
      it "raises ParseError for #{raw.inspect} (R2.2)" do
        expect { described_class.money(raw) }.to raise_error(BrlParser::ParseError)
      end
    end
  end

  describe ".date" do
    it "parses d/m/yyyy without zero padding (R2.3)" do
      expect(described_class.date("5/12/2023")).to eq(Date.new(2023, 12, 5))
    end

    it "parses zero padded dates" do
      expect(described_class.date("05/12/2023")).to eq(Date.new(2023, 12, 5))
    end

    it "ignores surrounding whitespace" do
      expect(described_class.date(" 10/6/2024 ")).to eq(Date.new(2024, 6, 10))
    end

    [ nil, "", "  ", "31/02/2023", "32/13/2024", "2023-12-05", "5/12/23", "abc" ].each do |raw|
      it "raises ParseError for #{raw.inspect} (R2.4)" do
        expect { described_class.date(raw) }.to raise_error(BrlParser::ParseError)
      end
    end
  end
end
