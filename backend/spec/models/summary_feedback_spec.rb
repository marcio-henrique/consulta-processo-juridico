require "rails_helper"

RSpec.describe SummaryFeedback do
  describe "validations" do
    it "is valid from the factory" do
      expect(build(:summary_feedback)).to be_valid
    end

    it "requires a summary and a user" do
      expect(build(:summary_feedback, summary: nil)).not_to be_valid
      expect(build(:summary_feedback, user: nil)).not_to be_valid
    end

    it "accepts true and false" do
      expect(build(:summary_feedback, helpful: true)).to be_valid
      expect(build(:summary_feedback, helpful: false)).to be_valid
    end

    it "rejects a missing vote" do
      expect(build(:summary_feedback, helpful: nil)).not_to be_valid
    end

    it "allows one vote per user and summary" do
      original = create(:summary_feedback)
      duplicate = build(:summary_feedback, summary: original.summary, user: original.user)
      expect(duplicate).not_to be_valid
    end

    it "allows other users to vote on the same summary" do
      original = create(:summary_feedback)
      expect(build(:summary_feedback, summary: original.summary)).to be_valid
    end

    it "enforces uniqueness with the database index as well" do
      original = create(:summary_feedback)
      duplicate = build(:summary_feedback, summary: original.summary, user: original.user)
      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "enforces the NOT NULL constraint on helpful" do
      feedback = build(:summary_feedback, helpful: nil)
      expect { feedback.save!(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end
  end

  describe "ownership" do
    it "is removed with its summary" do
      feedback = create(:summary_feedback)
      expect { feedback.summary.destroy! }.to change(described_class, :count).by(-1)
    end

    it "is removed with its user" do
      feedback = create(:summary_feedback)
      expect { feedback.user.destroy! }.to change(described_class, :count).by(-1)
    end

    it "starts empty for a new summary of the same lawsuit" do
      feedback = create(:summary_feedback)
      newer = create(:summary, lawsuit: feedback.summary.lawsuit)
      expect(newer.summary_feedbacks).to be_empty
    end
  end
end
