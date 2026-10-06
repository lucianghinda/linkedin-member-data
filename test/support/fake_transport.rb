# frozen_string_literal: true

# Stands in for Net::HTTP. Queue responses or exceptions; records every request.
class FakeTransport
  Response = Struct.new(:code, :body, :headers) do
    def [](name) = headers[name]
  end

  attr_reader :requests

  def initialize
    @queue = []
    @requests = []
  end

  def respond(code, body = nil, headers = {})
    body = JSON.generate(body) if body.is_a?(Hash) || body.is_a?(Array)
    @queue << Response.new(code.to_s, body, headers)
    self
  end

  def fail_with(exception)
    @queue << exception
    self
  end

  def call(request, uri)
    @requests << [request, uri]
    raise "FakeTransport: no response queued for #{request.method} #{uri}" if @queue.empty?

    item = @queue.shift
    raise item if item.is_a?(Exception)

    item
  end
end
