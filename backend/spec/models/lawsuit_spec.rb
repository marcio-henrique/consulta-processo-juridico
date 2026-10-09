require "rails_helper"

RSpec.describe Lawsuit, type: :model do
  subject(:lawsuit) { build(:lawsuit) }

  it "is valid with the factory defaults" do
    expect(lawsuit).to be_valid
  end

  %i[number forum court value number_of_authors].each do |attribute|
    it "requires #{attribute} (R3.4)" do
      lawsuit[attribute] = nil

      expect(lawsuit).not_to be_valid
      expect(lawsuit.errors).to include(attribute)
    end
  end

  it "rejects a number with an invalid check digit (R3.4)" do
    lawsuit.number = "1001399-31.2023.8.26.0071"

    expect(lawsuit).not_to be_valid
    expect(lawsuit.errors).to include(:number)
  end

  it "rejects a number that is not in the canonical format (R3.4)" do
    lawsuit.number = "10013993120238260070"

    expect(lawsuit).not_to be_valid
    expect(lawsuit.errors).to include(:number)
  end

  it "rejects a duplicate number (R3.1)" do
    existing = create(:lawsuit)
    lawsuit.number = existing.number

    expect(lawsuit).not_to be_valid
    expect(lawsuit.errors).to include(:number)
  end

  it "rejects a negative value (R3.4)" do
    lawsuit.value = -1

    expect(lawsuit).not_to be_valid
    expect(lawsuit.errors).to include(:value)
  end

  it "accepts a zero value (R3.4)" do
    lawsuit.value = 0

    expect(lawsuit).to be_valid
  end

  it "requires at least one author (R3.4)" do
    lawsuit.number_of_authors = 0

    expect(lawsuit).not_to be_valid
    expect(lawsuit.errors).to include(:number_of_authors)
  end

  it "requires an integer number of authors (R3.4)" do
    lawsuit.number_of_authors = 1.5

    expect(lawsuit).not_to be_valid
    expect(lawsuit.errors).to include(:number_of_authors)
  end

  it "deletes its movements when destroyed" do
    lawsuit = create(:lawsuit, :with_movements, movements_count: 2)

    expect { lawsuit.destroy }.to change(Movement, :count).by(-2)
  end
end
