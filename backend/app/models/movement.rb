class Movement < ApplicationRecord
  belongs_to :lawsuit

  validates :occurred_on, :title, :source_row, presence: true

  # Newest first; same-day ties keep CSV order (lowest source_row first). ADR-0005.
  scope :display_order, -> { order(occurred_on: :desc, source_row: :asc) }
  # Oldest first, for the LLM; exact reverse of display_order. ADR-0005.
  scope :chronological, -> { order(occurred_on: :asc, source_row: :desc) }
end
