# frozen_string_literal: true

# Quick tour of the gem against the real API.
# Run from the gem root:  LINKEDIN_ACCESS_TOKEN=... ruby -Ilib examples/demo.rb

require "linkedin/member_data"
require "json"

WEEK = 7 * 24 * 60 * 60

def show_authorization(client)
  puts "== Authorization"
  auth = client.authorization
  if auth
    puts "member: #{auth.member}, archiving since #{auth.regulated_at}, scopes: #{auth.scopes.join(", ")}"
  else
    puts "no authorization yet; calling enable_changelog!"
    client.enable_changelog!
  end
end

def show_profile(client)
  puts "\n== Snapshot: PROFILE (first row)"
  profile = client.snapshot(:profile).first
  puts profile ? JSON.pretty_generate(profile) : "no profile data yet (LinkedIn is still building the snapshot)"
end

def show_connections(client)
  puts "\n== Snapshot: CONNECTIONS (first 5 of a lazy walk)"
  client.snapshot(:connections).first(5).each do |row|
    puts "- #{row["First Name"]} #{row["Last Name"]} (#{row["Company"]}) connected #{row["Connected On"]}"
  end
end

def show_changelog(client)
  puts "\n== Changelog: last 7 days"
  events = client.changelog(since: Time.now - WEEK, count: 10).first(10)
  puts "no events yet; archiving starts at consent time" if events.empty?
  events.each do |event|
    puts "- #{event.processed_at} #{event.method.ljust(14)} #{event.resource_name} #{event.resource_id}"
  end
  puts "\nresume later with: client.changelog(since: #{events.last.processed_at_ms})" if events.any?
end

begin
  token = ENV.fetch("LINKEDIN_ACCESS_TOKEN") { abort "Set LINKEDIN_ACCESS_TOKEN to your access token" }
  client = LinkedIn::MemberData::Client.new(access_token: token)
  show_authorization(client)
  show_profile(client)
  show_connections(client)
  show_changelog(client)
  puts "\n== Domains available: #{LinkedIn::MemberData::Domains::ALL.size}"
rescue LinkedIn::MemberData::Unauthorized => error
  abort "token rejected (#{error.status}): #{error.message}"
rescue LinkedIn::MemberData::ApiError => error
  abort "API error #{error.status}: #{error.message}"
end
