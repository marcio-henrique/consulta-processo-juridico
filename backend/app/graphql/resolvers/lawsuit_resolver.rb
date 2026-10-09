module Resolvers
  # Query.lawsuit: validates the movements pagination arguments requested
  # anywhere in the selection (so a bad `first` is a UserError in the payload,
  # not a top-level error), then delegates to Lawsuits::Find.
  class LawsuitResolver
    def self.call(number:, context:, lookahead: nil)
      invalid_field = invalid_movements_argument(lookahead)
      return payload(nil, [ error(:INVALID_ARGUMENT, invalid_field) ]) if invalid_field

      result = Lawsuits::Find.call(number)
      return payload(result.lawsuit, []) if result.success?

      field = result.error_code == :INVALID_CNJ ? "number" : nil
      payload(nil, [ error(result.error_code, field) ])
    end

    def self.payload(lawsuit, errors)
      { lawsuit: lawsuit, errors: errors }
    end

    def self.error(code, field)
      Errors::Messages.build(code.to_s, Errors::Messages.for(code), field: field)
    end

    # Looks at every `movements` selection under `lawsuit` (aliases and
    # fragments included) and returns the first invalid argument name, or nil.
    def self.invalid_movements_argument(lookahead)
      return nil unless lookahead&.selected?

      lookahead.selection(:lawsuit).selections.each do |selection|
        next unless selection.name == :movements

        args = selection.arguments
        invalid = Lawsuits::MovementsPage.invalid_argument(
          first: args[:first] || Lawsuits::MovementsPage::DEFAULT_SIZE,
          after: args[:after]
        )
        return invalid if invalid
      end
      nil
    end
    private_class_method :payload, :error, :invalid_movements_argument
  end
end
