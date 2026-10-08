class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :summary_feedbacks, dependent: :destroy
end
