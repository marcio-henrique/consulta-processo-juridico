require "digest"

module Summaries
  # SHA-256 over the ordered (date, title, content) of a lawsuit's movements.
  # Part of the summary cache key: any new or edited movement changes it.
  # JSON encoding keeps field boundaries unambiguous.
  class Digest
    def self.call(movements)
      rows = movements.to_a
        .sort_by { |movement| [ movement.occurred_on, -movement.source_row ] }
        .map { |movement| [ movement.occurred_on.iso8601, movement.title.to_s, movement.content.to_s ] }
      ::Digest::SHA256.hexdigest(JSON.generate(rows))
    end
  end
end
