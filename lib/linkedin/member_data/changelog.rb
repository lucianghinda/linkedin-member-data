# frozen_string_literal: true

require_relative "changelog/page"

module LinkedIn
  module MemberData
    # Lazy view over GET /rest/memberChangeLogs (last 28 days).
    # The cursor is `startTime` = last `processedAt` seen. LinkedIn returns the
    # cursor event again on the next page, so events already seen are skipped
    # and iteration stops when a page brings nothing new, or when the last event
    # has no processedAt (the cursor cannot move).
    #
    # Known limit: if more than `count` events share one processedAt, the ones
    # beyond the first page are not reachable through the cursor.
    class Changelog
      include Enumerable

      PATH = "/rest/memberChangeLogs"
      COUNT_RANGE = (1..50)
      DEFAULT_COUNT = 10

      # Cursor state of one walk. A new one is built for every iteration.
      Walk = Struct.new(:start_time, :seen_ids) do
        # `page` is an undeduped Page. Returns a Page with only the fresh events
        # and moves the cursor; nil when nothing is new.
        def take(page)
          fresh = fresh_events(page)
          return if fresh.empty?

          advance(page)
          Page.new(events: fresh, raw: page.raw)
        end

        def fresh_events(page) = page.events.reject { |event| seen_ids.include?(event.id) }

        # Yields each start_time to the block to fetch a Page. Stops at the first
        # page with nothing new or when the cursor cannot move.
        def run(yielder)
          while (fresh_page = take(yield(start_time)))
            yielder << fresh_page
            break if start_time.nil?
          end
        end

        # Only the previous page is remembered: that is the documented overlap.
        def advance(page)
          self.seen_ids = page.events.map(&:id)
          self.start_time = page.next_start_time
        end
      end
      private_constant :Walk

      attr_reader :since, :count

      def initialize(connection, since: nil, count: DEFAULT_COUNT)
        @count = count
        ensure_count
        @connection = connection
        @since = Util.epoch_ms(since)
      end

      def each(&block)
        return enum_for(:each) unless block

        pages.each { |page| page.events.each(&block) }
        self
      end

      # Pages with already-seen events removed. Stops on the first page with no new events.
      # A yielded Page has filtered `events` but the unfiltered `raw` response.
      def pages = Enumerator.new { |yielder| each_page(yielder) }

      # One raw page from the API. No overlap handling.
      def page(start_time)
        params = { q: "memberAndApplication", count: count, startTime: start_time }
        Page.from_api(@connection.get(PATH, params))
      end

      private

      def each_page(yielder)
        Walk.new(since, []).run(yielder) { |start_time| page(start_time) }
      end

      def ensure_count
        return if count.is_a?(Integer) && COUNT_RANGE.cover?(count)

        raise ArgumentError, "count must be between #{COUNT_RANGE.min} and #{COUNT_RANGE.max}, got #{count.inspect}"
      end
    end
  end
end
