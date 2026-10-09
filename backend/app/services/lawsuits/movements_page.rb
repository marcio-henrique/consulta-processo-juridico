module Lawsuits
  # Offset-cursor pagination over a lawsuit's movements in display order
  # (occurred_on DESC, source_row ASC). Offsets are stable because movements
  # only change on import (ADR-0005).
  #
  # The cursor of the item at zero-based position i is Base64(urlsafe)("o:i");
  # `after: cursor` starts at position i + 1.
  class MovementsPage
    DEFAULT_SIZE = 25
    MAX_SIZE = 100
    CURSOR_FORMAT = /\Ao:(\d+)\z/

    Page = Struct.new(:nodes, :has_next_page, :has_previous_page, :start_cursor, :end_cursor, keyword_init: true)

    # Returns the name of the first invalid argument ("first" or "after"), or nil.
    def self.invalid_argument(first:, after: nil)
      return "first" unless first.is_a?(Integer) && first.between?(1, MAX_SIZE)
      return "after" if after && decode(after).nil?

      nil
    end

    def self.encode(position)
      Base64.urlsafe_encode64("o:#{position}", padding: false)
    end

    # Returns the position encoded in +cursor+, or nil when malformed.
    def self.decode(cursor)
      decoded = Base64.urlsafe_decode64(cursor.to_s)
      match = CURSOR_FORMAT.match(decoded)
      match && match[1].to_i
    rescue ArgumentError
      nil
    end

    def self.call(lawsuit, first: DEFAULT_SIZE, after: nil)
      new(lawsuit, first: first, after: after).call
    end

    def initialize(lawsuit, first:, after:)
      @lawsuit = lawsuit
      @first = first
      @after = after
      raise ArgumentError, "invalid pagination arguments" if self.class.invalid_argument(first: first, after: after)
    end

    def call
      offset = @after ? self.class.decode(@after) + 1 : 0
      rows = @lawsuit.movements.display_order.offset(offset).limit(@first + 1).to_a
      nodes = rows.first(@first)

      Page.new(
        nodes: nodes,
        has_next_page: rows.size > @first,
        has_previous_page: offset.positive?,
        start_cursor: nodes.empty? ? nil : self.class.encode(offset),
        end_cursor: nodes.empty? ? nil : self.class.encode(offset + nodes.size - 1)
      )
    end
  end
end
