# frozen_string_literal: true

# Namespace of the LinkedIn gems.
module LinkedIn
  # Ruby client and CLI for the LinkedIn Member Data Portability (Member) API.
  # Start with `Client`.
  #
  # @example
  #   client = LinkedIn::MemberData::Client.new(access_token: ENV["LINKEDIN_ACCESS_TOKEN"])
  #   client.snapshot(:connections).each { |row| puts row["First Name"] }
  module MemberData
    # Gem version.
    # @return [String]
    VERSION = "0.1.0"
  end
end
