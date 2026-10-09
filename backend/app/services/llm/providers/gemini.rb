module Llm
  module Providers
    # Thin Faraday adapter for the Gemini REST API (ADR-0002 decision log).
    #
    # - the key travels only in the `x-goog-api-key` header (never in the URL);
    # - the answer is read from `candidates[0].content.parts[].text`;
    # - finishReason MAX_TOKENS raises Llm::TruncatedError, SAFETY and blocked
    #   prompts raise Llm::ProviderError;
    # - error messages never include the key or any response body.
    class Gemini
      BASE_URL = "https://generativelanguage.googleapis.com".freeze
      TEMPERATURE = 0.2
      MODEL_ID = /\A[\w.\-]+\z/
      RETRYABLE_STATUSES = [ 500, 503 ].freeze

      def initialize(api_key:, connection: nil)
        @api_key = api_key.to_s.strip
        @connection = connection
      end

      def name
        "gemini"
      end

      # Keeps the key out of console/exception dumps.
      def inspect
        "#<#{self.class.name}>"
      end

      def complete(model:, system:, user:, max_output_tokens:, timeout: 20)
        raise ProviderError, "GEMINI_API_KEY is not configured (set it in .env)" if @api_key.empty?
        raise ProviderError, "Invalid model id in LLM configuration" unless model.to_s.match?(MODEL_ID)

        response = post(model, request_body(system, user, max_output_tokens), timeout)
        parse(response, model)
      end

      private

      def request_body(system, user, max_output_tokens)
        {
          systemInstruction: { parts: [ { text: system } ] },
          contents: [ { role: "user", parts: [ { text: user } ] } ],
          generationConfig: { temperature: TEMPERATURE, maxOutputTokens: max_output_tokens }
        }
      end

      def post(model, body, timeout)
        connection.post("/v1beta/models/#{model}:generateContent") do |request|
          request.headers["Content-Type"] = "application/json"
          request.headers["x-goog-api-key"] = @api_key
          request.options.timeout = timeout
          request.options.open_timeout = timeout
          request.body = JSON.generate(body)
        end
      rescue Faraday::TimeoutError
        raise TimeoutError, "Gemini request timed out"
      rescue Faraday::ConnectionFailed => e
        # Net::OpenTimeout surfaces as ConnectionFailed; keep it a timeout.
        raise TimeoutError, "Gemini connection timed out" if e.wrapped_exception.is_a?(::Timeout::Error)

        raise ProviderError.new("Gemini connection failed", retryable: true)
      rescue Faraday::Error => e
        raise ProviderError, "Gemini request failed (#{e.class.name})"
      end

      def connection
        @connection ||= Faraday.new(url: BASE_URL)
      end

      def parse(response, model)
        check_status(response.status)
        data = JSON.parse(response.body.to_s)
        raise ProviderError, "Gemini returned a malformed response" unless data.is_a?(Hash)

        block_reason = data.dig("promptFeedback", "blockReason")
        raise ProviderError, "Gemini blocked the prompt (#{block_reason})" if block_reason

        candidate = Array(data["candidates"]).first
        raise ProviderError, "Gemini returned no candidates" unless candidate.is_a?(Hash)

        finish_reason = candidate["finishReason"]
        raise TruncatedError, "Gemini stopped at the output token limit" if finish_reason == "MAX_TOKENS"
        raise ProviderError, "Gemini stopped with finishReason #{finish_reason}" unless [ nil, "STOP" ].include?(finish_reason)

        text = extract_text(candidate)
        raise ProviderError, "Gemini returned an empty answer" if text.blank?

        usage = data["usageMetadata"] || {}
        Result.new(
          text: text,
          input_tokens: usage["promptTokenCount"],
          output_tokens: output_tokens(usage),
          model: model
        )
      rescue JSON::ParserError
        raise ProviderError, "Gemini returned a malformed response"
      end

      def check_status(status)
        return if status == 200
        raise RateLimitError, "Gemini rate limit (HTTP 429)" if status == 429

        raise ProviderError.new("Gemini HTTP #{status}", retryable: RETRYABLE_STATUSES.include?(status))
      end

      def extract_text(candidate)
        parts = Array(candidate.dig("content", "parts"))
        parts.reject { |part| part["thought"] }.filter_map { |part| part["text"] }.join
      end

      def output_tokens(usage)
        return nil unless usage["candidatesTokenCount"] || usage["thoughtsTokenCount"]

        usage["candidatesTokenCount"].to_i + usage["thoughtsTokenCount"].to_i
      end
    end
  end
end
