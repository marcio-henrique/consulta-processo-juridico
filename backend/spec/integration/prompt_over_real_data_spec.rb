require "rails_helper"

# Runs the whole prompt pipeline (classifier, cleaner, budget) over the 100 real
# lawsuits of the challenge file (task A-13). Skipped when the CSV is absent.
RSpec.describe "Prompt pipeline over the real data", :real_data do
  let(:csv_path) { ENV.fetch("LAWSUITS_CSV_PATH", "/data/lawsuits_movements.csv") }

  before do
    skip "Real CSV not present at #{csv_path}" unless File.exist?(csv_path)
    Imports::LawsuitsCsv.call(csv_path)
  end

  def line_prefix(movement)
    "#{movement.occurred_on.strftime('%d/%m/%Y')} - #{movement.title.to_s.squish}"
  end

  it "builds a bounded, private prompt for every lawsuit, keeping the first and the last movements" do
    expect(Lawsuit.count).to eq(100)
    worst = nil

    Lawsuit.includes(:movements).find_each do |lawsuit|
      movements = lawsuit.movements.to_a
      ordered = movements.sort_by { |m| [ m.occurred_on, -m.source_row ] }
      prompt = Summaries::PromptBuilder.call(lawsuit, movements)
      user = prompt.user
      context = "lawsuit #{lawsuit.number}"

      expect(user.length).to be <= Summaries::PromptBuilder::MAX_PROMPT_CHARS, context
      expect(user).not_to match(/OAB\s*\d/), context
      expect(user).not_to match(/Advogados?\(s\):/), context
      expect(prompt.stats[:milestones]).to be > 0, context
      expect(prompt.stats[:movements]).to eq(movements.size), context

      # The first movement always survives; so do the last 15, except that
      # noise older than the last 5 movements is collapsed into counts.
      expect(user).to include(line_prefix(ordered.first)), context
      ordered.last(Summaries::PromptBuilder::LAST_N_ALWAYS).each_with_index do |movement, index|
        recent = index >= Summaries::PromptBuilder::LAST_N_ALWAYS - Summaries::PromptBuilder::NOISE_RECENT
        noise = Movements::Classifier.call(movement.title, content: movement.content) == :noise
        next if noise && !recent

        expect(user).to include(line_prefix(movement)), "#{context}: missing #{line_prefix(movement)}"
      end

      worst = { number: lawsuit.number, stats: prompt.stats } if worst.nil? || prompt.stats[:chars] > worst[:stats][:chars]
    end

    RSpec.configuration.reporter.message(
      "Worst-case prompt: #{worst[:number]} #{worst[:stats].inspect} (budget #{Summaries::PromptBuilder::MAX_PROMPT_CHARS} chars)"
    )
  end

  it "classifies every distinct title of the data without error and keeps known milestones" do
    titles = Movement.distinct.pluck(:title)
    classes = titles.to_h { |title| [ title, Movements::Classifier.call(title) ] }

    expect(classes.values.uniq).to match_array(%i[milestone context noise])
    expect(classes.select { |_, klass| klass == :milestone }.keys).to include("Julgada Procedente a Ação", "Acórdão registrado")
  end
end
