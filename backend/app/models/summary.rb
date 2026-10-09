class Summary < ApplicationRecord
  belongs_to :lawsuit
  has_many :summary_feedbacks, dependent: :destroy

  validates :body, :movements_digest, :prompt_version, :provider, :model, presence: true
  validates :movements_digest, uniqueness: { scope: [ :lawsuit_id, :prompt_version, :model ] }

  # Cached summary for the lawsuit's current movements and prompt version, or
  # nil. Never calls the LLM (ADR-0003). Several models may match; the newest wins.
  def self.current_for(lawsuit)
    where(
      lawsuit_id: lawsuit.id,
      movements_digest: Summaries::Digest.call(Movement.where(lawsuit_id: lawsuit.id)),
      prompt_version: Summaries::PromptBuilder::PROMPT_VERSION
    ).order(created_at: :desc, id: :desc).first
  end

  def generated_at
    created_at
  end
end
