module Summaries
  # Returns the cached summary for a lawsuit's current movements or generates
  # one synchronously (ADR-0003).
  #
  #   result = Summaries::Generate.call(lawsuit: lawsuit)
  #   result.success?      # => true
  #   result.summary       # => #<Summary ...>
  #   result.cache_hit     # => true when no provider call was made
  #   result.error_code    # => :SUMMARY_UNAVAILABLE on failure (nothing persisted)
  #
  # Cache key: (lawsuit_id, movements_digest, prompt_version, model). Concurrent
  # misses for the same key are serialized with a transaction-scoped advisory
  # lock; the waiter re-checks the cache and reuses the first result. The lock
  # is held during the provider call on purpose (simple at this scale).
  #
  # The stored `model` is the configured primary model (the cache key), even if
  # the fallback model answered. Prompts, movement contents and summary text are
  # never logged.
  class Generate
    STRICT_INSTRUCTION = "ATENÇÃO: a resposta anterior tinha um problema (tamanho ou valores em reais incorretos). " \
      "Responda novamente com no máximo 3 parágrafos curtos e no máximo 1.500 caracteres, em texto simples, " \
      "sem listas, títulos ou markdown. Copie os valores em reais exatamente como aparecem nos dados.".freeze

    Result = Struct.new(:summary, :cache_hit, :error_code, keyword_init: true) do
      def success?
        error_code.nil?
      end
    end

    def self.call(lawsuit:, client: nil)
      new(lawsuit, client).call
    end

    def initialize(lawsuit, client)
      @lawsuit = lawsuit
      @client = client
      @input_tokens = 0
      @output_tokens = 0
    end

    def call
      client = @client || Llm::Client.build
      # Fresh query on purpose: an already-loaded association could be stale.
      movements = Movement.where(lawsuit_id: @lawsuit.id).to_a
      key = cache_key(client, movements)

      cached = Summary.find_by(key)
      return hit(cached) if cached

      store(client, movements, key)
    rescue Llm::Error => error
      Rails.logger.error("Summary generation failed lawsuit_id=#{@lawsuit.id} error=#{error.class} message=#{error.message}")
      Result.new(error_code: :SUMMARY_UNAVAILABLE)
    end

    private

    def cache_key(client, movements)
      {
        lawsuit_id: @lawsuit.id,
        movements_digest: Digest.call(movements),
        prompt_version: PromptBuilder::PROMPT_VERSION,
        model: client.model
      }
    end

    def store(client, movements, key)
      Summary.transaction(requires_new: true) do
        lock(key)
        winner = Summary.find_by(key)
        next hit(winner) if winner

        started = monotonic_now
        body = produce(client, PromptBuilder.call(@lawsuit, movements))
        summary = Summary.create!(
          key.merge(body: body, provider: client.provider_name, input_tokens: @input_tokens, output_tokens: @output_tokens)
        )
        log("generated", summary, latency_ms: elapsed_ms(started), cache_hit: false)
        Result.new(summary: summary, cache_hit: false)
      end
    rescue ActiveRecord::RecordNotUnique
      winner = Summary.find_by(key) or raise
      hit(winner)
    end

    def lock(key)
      lock_id = ::Digest::SHA256.hexdigest(key.values.join("|"))[0, 15].to_i(16)
      Summary.connection.execute("SELECT pg_advisory_xact_lock(#{lock_id})")
    end

    # Calls the provider (with at most one corrective retry) and returns the
    # validated body text. The answer is corrected when it has more than 3
    # paragraphs, more than 2,000 characters, or an amount that is not in the
    # prompt (AmountCheck). Wrong amounts are never shown: if they survive the
    # retry the generation fails.
    def produce(client, prompt)
      strict = false
      begin
        result = request(client, prompt, strict: strict)
      rescue Llm::TruncatedError
        raise if strict

        strict = true
        retry
      end

      output = OutputValidator.call(result.text)
      wrong_amounts = AmountCheck.call(output.text, prompt.user)
      return output.text if output.within_limits? && wrong_amounts.empty?

      Rails.logger.warn("Summary answer needs correction paragraphs=#{output.paragraphs} chars=#{output.text.length} wrong_amounts=#{wrong_amounts.size}")
      return accept(output, wrong_amounts) if strict

      corrective_answer(client, prompt, output, wrong_amounts)
    end

    # Asks once more, strictly. If the retry fails or is still too long, the
    # limits are enforced locally instead of failing the user, but only when
    # the first answer had no wrong amounts.
    def corrective_answer(client, prompt, first_output, first_wrong_amounts)
      retried = OutputValidator.call(request(client, prompt, strict: true).text)
      accept(retried, AmountCheck.call(retried.text, prompt.user))
    rescue Llm::Error
      raise if first_wrong_amounts.any?

      OutputValidator.enforce(first_output.text)
    end

    def accept(output, wrong_amounts)
      raise Llm::ProviderError, "LLM answer has amounts that are not in the movements" if wrong_amounts.any?

      output.within_limits? ? output.text : OutputValidator.enforce(output.text)
    end

    def request(client, prompt, strict:)
      user = strict ? "#{prompt.user}\n\n#{STRICT_INSTRUCTION}" : prompt.user
      result = client.complete(system: prompt.system, user: user, max_output_tokens: PromptBuilder::MAX_OUTPUT_TOKENS)
      @input_tokens += result.input_tokens.to_i
      @output_tokens += result.output_tokens.to_i
      result
    end

    def hit(summary)
      log("served", summary, latency_ms: 0, cache_hit: true)
      Result.new(summary: summary, cache_hit: true)
    end

    def log(action, summary, latency_ms:, cache_hit:)
      Rails.logger.info(
        "Summary #{action} provider=#{summary.provider} model=#{summary.model} latency_ms=#{latency_ms} " \
        "input_tokens=#{summary.input_tokens} output_tokens=#{summary.output_tokens} cache_hit=#{cache_hit}"
      )
    end

    def monotonic_now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def elapsed_ms(started)
      ((monotonic_now - started) * 1000).round
    end
  end
end
