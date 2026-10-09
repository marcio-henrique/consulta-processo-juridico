class Summary < ApplicationRecord
  belongs_to :lawsuit
  has_many :summary_feedbacks, dependent: :destroy
end
