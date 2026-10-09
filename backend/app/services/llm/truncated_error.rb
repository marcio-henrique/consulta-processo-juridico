module Llm
  # The provider stopped because the output budget ran out (Gemini finishReason
  # MAX_TOKENS). Not retried by RetryPolicy; Summaries::Generate asks once more
  # with a stricter, shorter instruction and then gives up.
  class TruncatedError < ProviderError
  end
end
