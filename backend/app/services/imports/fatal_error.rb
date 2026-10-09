module Imports
  # The import cannot start or continue (missing/unreadable file, bad headers,
  # malformed CSV). Row-level problems are never fatal: they go to the report.
  class FatalError < StandardError; end
end
