module Types
  class ErrorCode < Types::BaseEnum
    value "INVALID_CNJ"
    value "NOT_FOUND"
    value "INVALID_ARGUMENT"
    value "UNAUTHENTICATED"
    value "SUMMARY_UNAVAILABLE"
    value "RATE_LIMITED"
    value "VALIDATION_FAILED"
  end
end
