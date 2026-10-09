module Llm
  Result = Struct.new(:text, :input_tokens, :output_tokens, :model, keyword_init: true)
end
