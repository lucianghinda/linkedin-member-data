# frozen_string_literal: true

# Downloads your whole LinkedIn snapshot into a folder, one JSON file per domain.
# Run from the gem root:  LINKEDIN_ACCESS_TOKEN=... ruby -Ilib examples/export.rb [DIR]

require "linkedin/member_data"

dir = ARGV.fetch(0, "linkedin-export")
token = ENV.fetch("LINKEDIN_ACCESS_TOKEN") { abort "Set LINKEDIN_ACCESS_TOKEN to your access token" }
client = LinkedIn::MemberData::Client.new(access_token: token)

begin
  manifest = client.export(dir) do |entry|
    case entry.status
    when :fetching then print "#{entry.domain}... "
    when :saved then puts "#{entry.rows} rows"
    when :empty then puts "empty"
    when :failed then puts "failed: #{entry.error}"
    end
  end
rescue LinkedIn::MemberData::Unauthorized, LinkedIn::MemberData::Forbidden => error
  abort "\ntoken rejected (#{error.status}): #{error.message}. A partial manifest is in #{dir}/manifest.json"
end

puts "\nWrote #{manifest.entries.size} domains to #{dir} (#{manifest.failed.size} failed). See #{manifest.path}."
exit(manifest.success? ? 0 : 1)
