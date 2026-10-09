module Llm
  class TimeoutError < Error
    def retryable?
      true
    end
  end
end
