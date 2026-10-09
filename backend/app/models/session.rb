class Session < ApplicationRecord
  LIFETIME = 14.days

  belongs_to :user

  scope :active, -> { where("expires_at > ?", Time.current) }

  def self.digest(raw_token)
    Auth::SessionToken.digest(raw_token)
  end

  def expired?
    expires_at <= Time.current
  end
end
