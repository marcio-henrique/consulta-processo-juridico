module Llm
  # Base class for every failure raised by the LLM layer. Messages never
  # contain prompts, movement contents or API keys.
  class Error < StandardError
    # Whether Llm::RetryPolicy may try again (timeout, 429, 500, 503).
    def retryable?
      false
    end
  end
end
