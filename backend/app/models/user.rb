class User < ApplicationRecord
  PASSWORD_MIN_LENGTH = 10
  PASSWORD_MAX_BYTES = 72 # bcrypt ignores everything after 72 bytes

  # Password rules are validated below with pt-BR messages from
  # Errors::Messages, so the built-in validations are turned off.
  has_secure_password validations: false

  has_many :sessions, dependent: :destroy
  has_many :summary_feedbacks, dependent: :destroy

  before_validation :normalize_email

  validate :email_format
  validate :email_uniqueness
  validate :password_rules, if: -> { new_record? || !password.nil? }

  def self.normalize_email(value)
    value.to_s.strip.downcase
  end

  private

  def normalize_email
    self.email = self.class.normalize_email(email)
  end

  def email_format
    return if email.match?(URI::MailTo::EMAIL_REGEXP) && email.length <= 254

    errors.add(:email, Errors::Messages::INVALID_EMAIL)
  end

  def email_uniqueness
    return if email.blank?
    # Emails are stored normalized, so a plain equality is case-insensitive.
    # Bound parameters keep the address out of the SQL log (filter_parameters).
    return unless self.class.where.not(id: id).exists?(email: email)

    errors.add(:email, Errors::Messages::EMAIL_TAKEN)
  end

  def password_rules
    value = password.to_s
    return if value.length >= PASSWORD_MIN_LENGTH && value.bytesize <= PASSWORD_MAX_BYTES

    errors.add(:password, Errors::Messages::INVALID_PASSWORD_LENGTH)
  end
end
