module Summaries
  # Manual quality evaluation behind `bin/rails summaries:eval`: generates and
  # prints summaries for the golden set so the Legal Expert can review them
  # (docs/skills/tune-llm-summary.md). Needs a real provider and key; it is not
  # part of CI. Printing summaries here is intentional (human review); nothing
  # is written to the repository.
  class Evaluation
    class FakeProviderError < StandardError; end

    # Lawsuit number => why it is in the set (docs/contracts/README.md 4.5).
    GOLDEN_SET = {
      "1019112-71.2025.8.26.0224" => "shortest (6 movements)",
      "1003790-87.2022.8.26.0071" => "longest (120 movements)",
      "1010953-94.2023.8.26.0100" => "most text (budget stress)",
      "1009608-88.2022.8.26.0016" => "settled by agreement, archived",
      "1004772-13.2022.8.26.0068" => "claim upheld",
      "1000061-57.2025.8.26.0068" => "claim partly upheld",
      "1030962-43.2024.8.26.0003" => "claim dismissed, with appeal",
      "1024104-25.2021.8.26.0577" => "partly upheld, enforcement phase",
      "1004283-74.2022.8.26.0003" => "archived",
      "1001399-31.2023.8.26.0070" => "demo lawsuit (46 movements)"
    }.freeze

    def self.call(numbers: GOLDEN_SET.keys, client: Llm::Client.build, out: $stdout, allow_fake: false)
      new(numbers, client, out, allow_fake).call
    end

    def initialize(numbers, client, out, allow_fake)
      @numbers = numbers
      @client = client
      @out = out
      @allow_fake = allow_fake
    end

    def call
      if @client.provider_name == "fake" && !@allow_fake
        raise FakeProviderError, "The fake provider only produces canned text. Set GEMINI_API_KEY (LLM_PROVIDER=auto or gemini) " \
          "or run with ALLOW_FAKE=1 to exercise the task offline."
      end

      @numbers.each { |number| evaluate(number) }
    end

    private

    def evaluate(number)
      lawsuit = Lawsuit.find_by(number: number)
      return @out.puts("#{number}: not found in the database\n\n") unless lawsuit

      movements = Movement.where(lawsuit_id: lawsuit.id).to_a
      stats = PromptBuilder.call(lawsuit, movements).stats
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = Generate.call(lawsuit: lawsuit, client: @client)
      latency_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round

      @out.puts("== #{number} (#{GOLDEN_SET[number] || 'custom'}; #{movements.size} movements) ==")
      @out.puts("prompt: #{stats[:chars]} chars, milestones=#{stats[:milestones]} context=#{stats[:context]} " \
        "noise=#{stats[:noise]} dropped_context=#{stats[:dropped_context]} dropped_milestones=#{stats[:dropped_milestones]}")
      return @out.puts("#{number}: generation failed (#{result.error_code})\n\n") unless result.success?

      summary = result.summary
      @out.puts(summary.body)
      @out.puts("-- provider=#{summary.provider} model=#{summary.model} tokens in=#{summary.input_tokens} " \
        "out=#{summary.output_tokens} latency=#{latency_ms} ms cache=#{result.cache_hit ? 'hit' : 'miss'}\n\n")
    end
  end
end
