require "rails_helper"

RSpec.describe User do
  def build_user(**attrs)
    build(:user, **attrs)
  end

  it "is valid from the factory" do
    expect(build_user).to be_valid
  end

  describe "email" do
    it "is trimmed and lower-cased before validation" do
      user = build_user(email: "  Ana.Silva@Example.COM ")
      user.valid?
      expect(user.email).to eq("ana.silva@example.com")
    end

    it "must have a valid format" do
      user = build_user(email: "not-an-email")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to eq([ Errors::Messages::INVALID_EMAIL ])
    end

    it "is required" do
      expect(build_user(email: "")).not_to be_valid
    end

    it "is unique case-insensitively" do
      create(:user, email: "ana@example.com")
      duplicate = build_user(email: "ANA@example.com")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to eq([ Errors::Messages::EMAIL_TAKEN ])
    end

    it "is protected by a case-insensitive unique index" do
      create(:user, email: "ana@example.com")
      clone = build_user(email: "ana@example.com")
      expect { clone.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "password" do
    {
      "9 characters" => [ "a" * 9, false ],
      "10 characters" => [ "a" * 10, true ],
      "72 bytes" => [ "a" * 72, true ],
      "73 bytes" => [ "a" * 73, false ],
      "36 multibyte characters (72 bytes)" => [ "é" * 36, true ],
      "37 multibyte characters (74 bytes)" => [ "é" * 37, false ]
    }.each do |label, (password, valid)|
      it "#{valid ? 'accepts' : 'rejects'} #{label}" do
        user = build_user(password: password)
        expect(user.valid?).to eq(valid)
        expect(user.errors[:password]).to eq([ Errors::Messages::INVALID_PASSWORD_LENGTH ]) unless valid
      end
    end

    it "is required for a new user" do
      user = build_user(password: nil)
      expect(user).not_to be_valid
      expect(user.errors[:password]).to eq([ Errors::Messages::INVALID_PASSWORD_LENGTH ])
    end

    it "stores only a bcrypt digest" do
      user = create(:user, password: "a-very-safe-password")
      expect(user.password_digest).to start_with("$2")
      expect(user.password_digest).not_to include("a-very-safe-password")
      expect(user.authenticate("a-very-safe-password")).to eq(user)
      expect(user.authenticate("wrong-password-123")).to be_falsey
    end

    it "does not need to be re-supplied to update other attributes of a persisted user" do
      user = User.find(create(:user).id)
      user.updated_at = Time.current
      expect(user).to be_valid
    end
  end
end
