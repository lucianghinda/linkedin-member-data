# frozen_string_literal: true

require "test_helper"

class LinkedIn::MemberData::ErrorsTest < Minitest::Test
  include LinkedIn::MemberData

  FakeResponse = Struct.new(:code, :body, :headers) do
    def [](name) = headers[name]
  end

  def response(code, body = nil, headers = {})
    FakeResponse.new(code.to_s, body, headers)
  end

  def test_maps_known_statuses_to_classes
    {
      401 => Unauthorized, 403 => Forbidden, 404 => NotFound,
      426 => VersionError, 429 => RateLimited, 500 => ServerError, 503 => ServerError
    }.each do |status, klass|
      assert_instance_of klass, ApiError.from_response(response(status))
    end
  end

  def test_unknown_4xx_is_plain_api_error
    error = ApiError.from_response(response(418))

    assert_instance_of ApiError, error
    assert_equal 418, error.status
    assert_equal "HTTP 418", error.message
  end

  def test_reads_message_and_code_from_json_body
    body = '{"message":"No data found for this memberId","serviceErrorCode":100,"status":404}'
    error = ApiError.from_response(response(404, body))

    assert_equal "No data found for this memberId", error.message
    assert_equal 100, error.code
    assert_equal(JSON.parse(body), error.body)
  end

  def test_falls_back_to_code_key
    error = ApiError.from_response(response(400, '{"code":"INVALID"}'))

    assert_equal "INVALID", error.code
  end

  def test_code_is_nil_when_body_has_no_code_keys
    error = ApiError.from_response(response(400, '{"message":"bad"}'))

    assert_nil error.code
  end

  def test_ignores_non_json_body
    error = ApiError.from_response(response(502, "<html>bad gateway</html>"))

    assert_equal "HTTP 502", error.message
    assert_nil error.body
  end

  def test_ignores_json_body_that_is_not_an_object
    error = ApiError.from_response(response(500, "[1, 2, 3]"))

    assert_equal "HTTP 500", error.message
    assert_nil error.body
  end

  def test_rate_limited_reads_retry_after
    error = ApiError.from_response(response(429, nil, "Retry-After" => "7"))

    assert_equal 7, error.retry_after
    assert_predicate error, :retryable?
  end

  def test_only_rate_limited_and_server_errors_are_retryable
    assert_predicate ApiError.from_response(response(500)), :retryable?
    refute_predicate ApiError.from_response(response(401)), :retryable?
    refute_predicate ApiError.from_response(response(404)), :retryable?
  end

  def test_hierarchy
    assert_operator ConfigurationError, :<, Error
  end

  def test_api_error_hierarchy
    assert_operator ConnectionError, :<, Error
    assert_operator ApiError, :<, Error
    assert_operator RateLimited, :<, ApiError
  end

  def test_connection_error_is_retryable_without_retry_after
    error = ConnectionError.new("boom")

    assert_predicate error, :retryable?
    assert_nil error.retry_after
  end
end
