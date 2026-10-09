class SummaryFeedback < ApplicationRecord
  belongs_to :summary
  belongs_to :user

  # `presence` would reject false, so check the two valid values explicitly.
  validates :helpful, inclusion: { in: [ true, false ] }
  validates :user_id, uniqueness: { scope: :summary_id }
end
