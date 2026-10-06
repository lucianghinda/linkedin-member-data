# frozen_string_literal: true

require "json"

module LinkedIn
  module MemberData
    class CLI
      # Data goes to a file or stdout. Progress and errors go to stderr.
      class Output
        def initialize(stdout, stderr)
          @stdout = stdout
          @stderr = stderr
        end

        def write(data, path = nil)
          json = JSON.pretty_generate(data)
          path ? File.write(path, json) : @stdout.puts(json)
        end

        def line(text) = @stdout.puts(text)

        def error(text) = @stderr.puts(text)

        alias progress error
      end
    end
  end
end
