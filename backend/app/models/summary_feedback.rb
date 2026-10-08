class SummaryFeedback < ApplicationRecord
  belongs_to :summary
  belongs_to :user
end
