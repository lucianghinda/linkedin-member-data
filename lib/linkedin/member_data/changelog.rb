# frozen_string_literal: true

module LinkedIn
  module MemberData
    # Lazy view over GET /rest/memberChangeLogs (last 28 days).
    # The cursor is `startTime` = last `processedAt` seen. LinkedIn returns the
    # cursor event again on the next page, so events already seen are skipped
    # and iteration stops when a page brings nothing new.
    class Changelog
      include Enumerable

      PATH = "/rest/memberChangeLogs"
      COUNT_RANGE = (1..50)
      DEFAULT_COUNT = 10

      Page = Data.define(:events, :raw) do
        def self.from_api(raw)
          new(events: raw.fetch("elements", []).map { |element| Event.from_api(element) }, raw: raw)
        end

        def next_start_time = events.last&.processed_at_ms
      end

      # Cursor state of one walk. A new one is built for every iteration.
      Walk = Struct.new(:start_time, :seen_ids) do
        # Fresh Page for a raw page and moves the cursor; nil when nothing is new.
        def take(raw_page)
          fresh = fresh_events(raw_page)
          return if fresh.empty?

          advance(raw_page)
          Page.new(events: fresh, raw: raw_page.raw)
        end

        def fresh_events(raw_page) = raw_page.events.reject { |event| seen_ids.include?(event.id) }

        def advance(raw_page)
          self.seen_ids = raw_page.events.map(&:id)
          self.start_time = raw_page.next_start_time
        end
      end
      private_constant :Walk

      attr_reader :since, :count

      def initialize(connection, since: nil, count: DEFAULT_COUNT)
        ensure_count(count)
        @connection = connection
        @since = Util.epoch_ms(since)
        @count = count
      end

      def each(&block)
        return enum_for(:each) unless block

        pages.each { |page| page.events.each(&block) }
        self
      end

      # Pages with already-seen events removed. Stops on the first page with no new events.
      def pages = Enumerator.new { |yielder| each_page(yielder) }

      # One raw page from the API. No overlap handling.
      def page(start_time)
        params = { q: "memberAndApplication", count: count, startTime: start_time }
        Page.from_api(@connection.get(PATH, params))
      end

      private

      def each_page(yielder)
        walk = Walk.new(since, [])
        while (fresh_page = walk.take(page(walk.start_time)))
          yielder << fresh_page
        end
      end

      def ensure_count(count)
        return if COUNT_RANGE.cover?(count)

        raise ArgumentError, "count must be between #{COUNT_RANGE.min} and #{COUNT_RANGE.max}, got #{count}"
      end
    end
  end
end
