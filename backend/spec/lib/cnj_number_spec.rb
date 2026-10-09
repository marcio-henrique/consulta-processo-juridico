require "rails_helper"
require "csv"

RSpec.describe CnjNumber do
  describe ".parse" do
    context "with a valid number" do
      it "returns the canonical form for an already formatted number (R1.1)" do
        result = described_class.parse("1001399-31.2023.8.26.0070")

        expect(result).to be_valid
        expect(result.formatted).to eq("1001399-31.2023.8.26.0070")
        expect(result.error).to be_nil
      end

      it "formats a digits-only number (R1.1)" do
        expect(described_class.parse("10013993120238260070").formatted).to eq("1001399-31.2023.8.26.0070")
      end

      it "ignores surrounding whitespace and mixed separators (R1.1)" do
        expect(described_class.parse("  1001399-31 2023/8.26.0070\n").formatted).to eq("1001399-31.2023.8.26.0070")
      end

      it "accepts the challenge statement example (R1.1)" do
        result = described_class.parse("1002271-82.2025.8.26.0003")

        expect(result).to be_valid
        expect(result.formatted).to eq("1002271-82.2025.8.26.0003")
      end

      it "exposes the segments (R1.4)" do
        result = described_class.parse("1002271-82.2025.8.26.0003")

        expect(result.segments).to eq(
          sequence: "1002271", check_digits: "82", year: "2025",
          justice_branch: "8", court: "26", origin: "0003"
        )
      end
    end

    context "with an invalid format" do
      [
        [ "blank", "" ],
        [ "nil", nil ],
        [ "19 digits", "1001399-31.2023.8.26.007" ],
        [ "21 digits", "1001399-31.2023.8.26.00700" ],
        [ "letters only", "abcdefg" ],
        [ "too short", "123" ]
      ].each do |label, input|
        it "reports invalid_format for #{label} (R1.2)" do
          result = described_class.parse(input)

          expect(result).not_to be_valid
          expect(result.error).to eq(:invalid_format)
          expect(result.formatted).to be_nil
          expect(result.segments).to be_nil
        end
      end
    end

    context "with a wrong check digit" do
      it "reports invalid_check_digit (R1.3)" do
        result = described_class.parse("1001399-31.2023.8.26.0071")

        expect(result).not_to be_valid
        expect(result.error).to eq(:invalid_check_digit)
      end

      it "still exposes the formatted form and segments" do
        result = described_class.parse("1001399-00.2023.8.26.0070")

        expect(result.formatted).to eq("1001399-00.2023.8.26.0070")
        expect(result.segments[:check_digits]).to eq("00")
      end
    end
  end

  describe ".check_digits" do
    it "computes 98 - (digits + '00') mod 97, zero padded (R1.3)" do
      expect(described_class.check_digits(sequence: "1001399", year: "2023", justice_branch: "8", court: "26", origin: "0070"))
        .to eq("31")
    end

    it "zero pads single digit results" do
      # Find a number whose check digits are < 10 to prove padding.
      origin = (0..9999).map { |i| format("%04d", i) }.find do |o|
        described_class.check_digits(sequence: "1000000", year: "2023", justice_branch: "8", court: "26", origin: o).to_i < 10
      end

      digits = described_class.check_digits(sequence: "1000000", year: "2023", justice_branch: "8", court: "26", origin: origin)
      expect(digits).to match(/\A0\d\z/)
    end
  end

  describe "does not depend on Rails (R1.5)" do
    it "has no reference to Rails or ActiveSupport in its source" do
      source = File.read(Rails.root.join("app/lib/cnj_number.rb"))

      expect(source).not_to match(/Rails|ActiveSupport|ActiveRecord/)
    end
  end

  describe "real data" do
    let(:csv_path) { ENV.fetch("LAWSUITS_CSV_PATH", "/data/lawsuits_movements.csv") }

    it "accepts every distinct lawsuit number of the provided CSV" do
      skip "CSV not present at #{csv_path}" unless File.exist?(csv_path)

      numbers = CSV.read(csv_path, headers: true).map { |row| row["lawsuit_number"] }.uniq

      expect(numbers.size).to eq(100)
      expect(numbers.map { |n| described_class.parse(n) }).to all(be_valid)
    end
  end
end
