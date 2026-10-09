namespace :summaries do
  desc "Generate and print summaries for the golden set (needs GEMINI_API_KEY; not run in CI). " \
    "LAWSUITS=n1,n2 overrides the set; ALLOW_FAKE=1 allows the offline fake provider."
  task eval: :environment do
    numbers = ENV["LAWSUITS"].to_s.split(",").map(&:strip).reject(&:empty?)
    options = { allow_fake: ENV["ALLOW_FAKE"] == "1" }
    options[:numbers] = numbers if numbers.any?
    Summaries::Evaluation.call(**options)
  rescue Summaries::Evaluation::FakeProviderError => e
    abort "summaries:eval: #{e.message}"
  end
end
