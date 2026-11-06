# frozen_string_literal: true

module AslanPayment
  class Error < StandardError
    CODES = %w[
      AUTHENTICATION_ERROR
      AUTHORIZATION_ERROR
      VALIDATION_ERROR
      NOT_FOUND
      RATE_LIMITED
      IDEMPOTENCY_ERROR
      NETWORK_ERROR
      SERVER_ERROR
      PROVIDER_ACCOUNT_NOT_FOUND
      PROVIDER_ACCOUNT_INACTIVE
      PROVIDER_ACCOUNT_UNSUPPORTED
      PROVIDER_ACCOUNT_RECURRING_DISABLED
    ].freeze

    attr_reader :code, :http_status, :details, :request_id

    # @param code [String] one of CODES
    # @param message [String] human-readable message
    # @param http_status [Integer, nil]
    # @param details [Hash, nil]
    # @param request_id [String, nil]
    def initialize(code, message, http_status: nil, details: nil, request_id: nil)
      @code = code
      @http_status = http_status
      @details = details
      @request_id = request_id
      super(message)
    end

    # Map an HTTP status code to an error code.
    # @param status [Integer]
    # @param server_code [String, nil]
    # @return [String]
    def self.code_for_status(status, server_code = nil)
      return "VALIDATION_ERROR" if server_code == "VALIDATION_ERROR"
      return "IDEMPOTENCY_ERROR" if server_code == "IDEMPOTENCY_ERROR"
      return server_code if server_code.to_s.start_with?("PROVIDER_ACCOUNT_") && CODES.include?(server_code)

      case status
      when 401 then "AUTHENTICATION_ERROR"
      when 403 then "AUTHORIZATION_ERROR"
      when 404 then "NOT_FOUND"
      when 409 then "IDEMPOTENCY_ERROR"
      when 422 then "VALIDATION_ERROR"
      when 429 then "RATE_LIMITED"
      else
        status >= 500 ? "SERVER_ERROR" : "VALIDATION_ERROR"
      end
    end
  end
end
