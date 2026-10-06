# frozen_string_literal: true

module LinkedIn
  module MemberData
    class Changelog
      # One response page of changelog events. Immutable.
      #
      # @!attribute [r] events
      #   @return [Array<Event>] events of this page, in API order (oldest first).
      # @!attribute [r] raw
      #   @return [Hash] the parsed response body.
      Page = Data.define(:events, :raw) do
        # Builds a page from a parsed response body. A missing `elements` key gives no events.
        #
        # @param raw [Hash] parsed JSON body of the API response.
        # @return [Changelog::Page]
        def self.from_api(raw)
          new(events: raw.fetch("elements", []).map { |element| Event.from_api(element) }, raw: raw)
        end

        # Cursor for the next request: `processedAt` of the last event, in epoch milliseconds.
        #
        # @return [Integer, nil] `nil` when the page has no events or the last event has no `processedAt`.
        def next_start_time = events.last&.processed_at_ms
      end
    end
  end
end
