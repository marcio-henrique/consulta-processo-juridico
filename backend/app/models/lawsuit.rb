class Lawsuit < ApplicationRecord
  has_many :movements, dependent: :destroy
  has_many :summaries, dependent: :destroy
end
