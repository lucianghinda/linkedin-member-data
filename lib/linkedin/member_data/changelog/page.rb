# frozen_string_literal: true

module LinkedIn
  module MemberData
    class Changelog
      # One response page. `events` are Event objects; `raw` is the parsed body.
      Page = Data.define(:events, :raw) do
        def self.from_api(raw)
          new(events: raw.fetch("elements", []).map { |element| Event.from_api(element) }, raw: raw)
        end

        def next_start_time = events.last&.processed_at_ms
      end
    end
  end
end
