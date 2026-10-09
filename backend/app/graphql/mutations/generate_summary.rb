module Mutations
  # Mutation.generateSummary (ADR-0003): validates the number, then returns the
  # cached summary or generates one synchronously. Failures are data
  # (UserError), never internal details. Authentication and the per-user
  # throttle belong to spec 06 (guard).
  class GenerateSummary
    def self.call(lawsuit_number:, context:)
      found = Lawsuits::Find.call(lawsuit_number)
      return payload(nil, error(found.error_code, found.error_code == :INVALID_CNJ ? "number" : nil)) unless found.success?

      result = Summaries::Generate.call(lawsuit: found.lawsuit)
      return payload(result.summary, nil) if result.success?

      payload(nil, error(result.error_code, nil))
    end

    def self.payload(summary, error)
      { summary: summary, errors: [ error ].compact }
    end

    def self.error(code, field)
      Errors::Messages.build(code.to_s, Errors::Messages.for(code), field: field)
    end
    private_class_method :payload, :error
  end
end
