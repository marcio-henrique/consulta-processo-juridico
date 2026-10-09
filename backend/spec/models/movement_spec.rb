require "rails_helper"

RSpec.describe Movement, type: :model do
  subject(:movement) { build(:movement) }

  it "is valid with the factory defaults" do
    expect(movement).to be_valid
  end

  %i[occurred_on title source_row].each do |attribute|
    it "requires #{attribute} (R3.4)" do
      movement[attribute] = nil

      expect(movement).not_to be_valid
      expect(movement.errors).to include(attribute)
    end
  end

  it "allows blank content (R3.2)" do
    movement.content = nil

    expect(movement).to be_valid
  end

  it "requires a lawsuit" do
    movement.lawsuit = nil

    expect(movement).not_to be_valid
  end

  describe "ordering scopes" do
    let(:lawsuit) { create(:lawsuit) }
    let!(:old) { create(:movement, lawsuit: lawsuit, occurred_on: Date.new(2024, 1, 1), source_row: 5) }
    let!(:new_late_row) { create(:movement, lawsuit: lawsuit, occurred_on: Date.new(2024, 6, 10), source_row: 9) }
    let!(:new_early_row) { create(:movement, lawsuit: lawsuit, occurred_on: Date.new(2024, 6, 10), source_row: 2) }

    it "display_order is newest first, ties by lowest source_row (ADR-0005)" do
      expect(lawsuit.movements.display_order).to eq([ new_early_row, new_late_row, old ])
    end

    it "chronological is oldest first, ties by highest source_row (ADR-0005)" do
      expect(lawsuit.movements.chronological).to eq([ old, new_late_row, new_early_row ])
    end
  end
end
