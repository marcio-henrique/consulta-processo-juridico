module Llm
  module Providers
    # Offline, deterministic provider for development without a key, tests and
    # CI. It reads the lawsuit metadata lines of the user prompt
    # (see Summaries::PromptBuilder) and writes a valid 3-paragraph pt-BR text.
    #
    # Test hooks: `failures:` raises the given errors on the first calls,
    # `texts:` scripts the answers (last one repeats), `latency:` sleeps to make
    # concurrent calls overlap, and `calls` records every request.
    class Fake
      MODEL = "fake-v1".freeze
      NOT_INFORMED = "não informado".freeze

      attr_reader :calls

      def initialize(failures: [], texts: nil, latency: 0)
        @failures = failures.dup
        @texts = texts&.dup
        @latency = latency
        @calls = []
        @mutex = Mutex.new
      end

      def name
        "fake"
      end

      def model
        MODEL
      end

      def complete(model:, system:, user:, max_output_tokens:, timeout: nil)
        failure, scripted = @mutex.synchronize do
          @calls << { model: model, system: system, user: user, max_output_tokens: max_output_tokens }
          [ @failures.shift, next_text ]
        end
        sleep(@latency) if @latency.positive?
        raise failure if failure

        text = scripted || build_text(user)
        Result.new(text: text, input_tokens: estimate(system, user), output_tokens: estimate(text), model: MODEL)
      end

      private

      def next_text
        return nil if @texts.nil? || @texts.empty?

        @texts.size > 1 ? @texts.shift : @texts.first
      end

      def build_text(user)
        number = field(user, "Número do processo")
        forum = field(user, "Foro")
        court = field(user, "Vara")
        value = field(user, "Valor da causa")
        last = field(user, "Última movimentação")

        [
          "O processo #{number} tramita em #{court}, no #{forum}, e discute um valor de #{value}.",
          "Ao longo do processo, houve várias etapas: apresentação do pedido, defesa, decisões do juiz e publicações oficiais.",
          "A última movimentação registrada foi em #{last}. Este resumo foi gerado automaticamente a partir dos dados disponíveis."
        ].join("\n\n")
      end

      def field(user, label)
        user[/^#{Regexp.escape(label)}: (.+)$/, 1]&.strip.presence || NOT_INFORMED
      end

      # Rough estimate (about 4 characters per token); good enough for logs.
      def estimate(*texts)
        [ (texts.sum(&:length) / 4.0).ceil, 1 ].max
      end
    end
  end
end
