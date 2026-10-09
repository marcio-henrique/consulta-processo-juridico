require "rails_helper"

RSpec.describe Summary do
  describe "validations" do
    it "is valid from the factory" do
      expect(build(:summary)).to be_valid
    end

    %i[body movements_digest prompt_version provider model].each do |attribute|
      it "requires #{attribute}" do
        expect(build(:summary, attribute => " ")).not_to be_valid
      end
    end

    it "does not allow two rows for the same cache key" do
      original = create(:summary)
      duplicate = build(:summary, lawsuit: original.lawsuit, movements_digest: original.movements_digest,
        prompt_version: original.prompt_version, model: original.model)

      expect(duplicate).not_to be_valid
    end

    it "keeps older rows when the digest, prompt version or model differ" do
      original = create(:summary)

      expect(build(:summary, lawsuit: original.lawsuit, movements_digest: original.movements_digest,
        prompt_version: "v2", model: original.model)).to be_valid
      expect(build(:summary, lawsuit: original.lawsuit, movements_digest: original.movements_digest,
        prompt_version: original.prompt_version, model: "other-model")).to be_valid
    end

    it "enforces the cache key with the unique index as well" do
      original = create(:summary)
      duplicate = build(:summary, lawsuit: original.lawsuit, movements_digest: original.movements_digest,
        prompt_version: original.prompt_version, model: original.model)

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "#generated_at" do
    it "is the creation time" do
      summary = create(:summary)

      expect(summary.generated_at).to eq(summary.created_at)
    end
  end

  describe ".current_for" do
    let(:lawsuit) { create(:lawsuit) }

    before { create(:movement, lawsuit: lawsuit, source_row: 1) }

    def digest
      Summaries::Digest.call(lawsuit.movements)
    end

    it "returns nil when there is no summary" do
      expect(described_class.current_for(lawsuit)).to be_nil
    end

    it "returns the summary that matches the current digest and prompt version" do
      summary = create(:summary, lawsuit: lawsuit, movements_digest: digest, prompt_version: Summaries::PromptBuilder::PROMPT_VERSION)

      expect(described_class.current_for(lawsuit)).to eq(summary)
    end

    it "ignores summaries of an older digest (movements changed)" do
      create(:summary, lawsuit: lawsuit, movements_digest: digest, prompt_version: Summaries::PromptBuilder::PROMPT_VERSION)
      create(:movement, lawsuit: lawsuit, source_row: 2, title: "Arquivado Definitivamente")

      expect(described_class.current_for(lawsuit)).to be_nil
    end

    it "ignores summaries of another prompt version" do
      create(:summary, lawsuit: lawsuit, movements_digest: digest, prompt_version: "v0")

      expect(described_class.current_for(lawsuit)).to be_nil
    end

    it "ignores summaries of other lawsuits" do
      create(:summary, movements_digest: digest, prompt_version: Summaries::PromptBuilder::PROMPT_VERSION)

      expect(described_class.current_for(lawsuit)).to be_nil
    end

    it "returns the most recent one when several models match" do
      version = Summaries::PromptBuilder::PROMPT_VERSION
      create(:summary, lawsuit: lawsuit, movements_digest: digest, prompt_version: version, model: "old", created_at: 2.days.ago)
      newest = create(:summary, lawsuit: lawsuit, movements_digest: digest, prompt_version: version, model: "new", created_at: 1.hour.ago)

      expect(described_class.current_for(lawsuit)).to eq(newest)
    end
  end
end
