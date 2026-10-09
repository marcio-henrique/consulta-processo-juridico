require "rails_helper"

RSpec.describe Summaries::Digest do
  let(:movement_class) { Struct.new(:occurred_on, :title, :content, :source_row, keyword_init: true) }

  def movement(date, title, content, row)
    movement_class.new(occurred_on: Date.parse(date), title: title, content: content, source_row: row)
  end

  let(:movements) do
    [
      movement("2024-01-01", "Distribuição por Sorteio", nil, 3),
      movement("2024-01-02", "Petição Juntada", "texto", 2),
      movement("2024-01-02", "Despacho", "outro", 1)
    ]
  end

  it "returns a SHA-256 hex digest" do
    expect(described_class.call(movements)).to match(/\A\h{64}\z/)
  end

  it "does not depend on the order the movements are given in" do
    expect(described_class.call(movements.reverse)).to eq(described_class.call(movements))
  end

  it "changes when a movement is added" do
    extra = movements + [ movement("2024-02-01", "Arquivado Definitivamente", nil, 0) ]

    expect(described_class.call(extra)).not_to eq(described_class.call(movements))
  end

  it "changes when a date, title or content changes" do
    base = described_class.call(movements)

    [
      [ "2024-01-09", "Petição Juntada", "texto" ],
      [ "2024-01-02", "Petição Juntada!", "texto" ],
      [ "2024-01-02", "Petição Juntada", "texto novo" ]
    ].each do |date, title, content|
      changed = [ movements[0], movement(date, title, content, 2), movements[2] ]
      expect(described_class.call(changed)).not_to eq(base)
    end
  end

  it "does not depend on source_row values themselves" do
    renumbered = movements.map { |m| m.dup.tap { |copy| copy.source_row += 100 } }

    expect(described_class.call(renumbered)).to eq(described_class.call(movements))
  end

  it "treats nil and empty content alike" do
    with_nil = [ movement("2024-01-01", "A", nil, 1) ]
    with_empty = [ movement("2024-01-01", "A", "", 1) ]

    expect(described_class.call(with_nil)).to eq(described_class.call(with_empty))
  end

  it "does not confuse field boundaries" do
    one = [ movement("2024-01-01", "A|B", "C", 1) ]
    two = [ movement("2024-01-01", "A", "B|C", 1) ]

    expect(described_class.call(one)).not_to eq(described_class.call(two))
  end

  it "accepts an ActiveRecord relation" do
    lawsuit = create(:lawsuit)
    create(:movement, lawsuit: lawsuit, source_row: 1)

    expect(described_class.call(lawsuit.movements)).to match(/\A\h{64}\z/)
  end

  it "has a stable value for an empty list" do
    expect(described_class.call([])).to eq(Digest::SHA256.hexdigest("[]"))
  end
end
