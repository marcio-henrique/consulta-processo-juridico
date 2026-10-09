require "rails_helper"

# Smoke test: every factory builds a valid, persistable record. Catches
# typos/invalid defaults early instead of failing deep inside unrelated specs.
RSpec.describe "Factories" do
  it "lint: every factory is valid" do
    FactoryBot.lint
  end

  it "builds a lawsuit with the :with_movements trait" do
    lawsuit = create(:lawsuit, :with_movements, movements_count: 3)

    expect(lawsuit.movements.count).to eq(3)
  end
end
