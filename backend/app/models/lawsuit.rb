class Lawsuit < ApplicationRecord
  has_many :movements, dependent: :destroy
  has_many :summaries, dependent: :destroy

  validates :number, presence: true, uniqueness: true
  validates :forum, :court, presence: true
  validates :value, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :number_of_authors, presence: true,
    numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validate :number_is_canonical_cnj

  private

  def number_is_canonical_cnj
    return if number.blank?

    result = CnjNumber.parse(number)
    errors.add(:number, :invalid) unless result.valid? && result.formatted == number
  end
end
