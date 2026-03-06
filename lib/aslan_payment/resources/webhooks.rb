# frozen_string_literal: true

require "openssl"
require "json"
require_relative "../error"

module AslanPayment
  class Webhooks
    DEFAULT_TOLERANCE = 300 # seconds

    # @param webhook_secret [String] the webhook signing secret (whsec_*)
    def initialize(webhook_secret)
      @webhook_secret = webhook_secret
    end

    # Verify a webhook signature and return the parsed event.
    #
    # @param payload [String] raw request body
    # @param signature [String] value of the Aslan-Signature header
    # @param tolerance [Integer] max age in seconds (default: 300)
    # @return [Hash] parsed webhook event
    # @raise [AslanPayment::Error] if verification fails
    def verify(payload, signature, tolerance: DEFAULT_TOLERANCE)
      parts = signature.split(",")
      timestamp_part = parts.find { |p| p.start_with?("t=") }
      signature_part = parts.find { |p| p.start_with?("v1=") }

      unless timestamp_part && signature_part
        raise Error.new("VALIDATION_ERROR", "Invalid webhook signature format")
      end

      timestamp = timestamp_part[2..].to_i
      expected_sig = signature_part[3..]

      if timestamp_part[2..].empty? || timestamp.zero?
        raise Error.new("VALIDATION_ERROR", "Invalid webhook timestamp")
      end

      now = Time.now.to_i
      if (now - timestamp).abs > tolerance
        raise Error.new("VALIDATION_ERROR", "Webhook timestamp too old")
      end

      signed_payload = "#{timestamp}.#{payload}"
      computed_sig = OpenSSL::HMAC.hexdigest("SHA256", @webhook_secret, signed_payload)

      unless secure_compare(expected_sig, computed_sig)
        raise Error.new("VALIDATION_ERROR", "Webhook signature verification failed")
      end

      begin
        JSON.parse(payload)
      rescue JSON::ParserError
        raise Error.new("VALIDATION_ERROR", "Invalid webhook payload JSON")
      end
    end

    private

    # Constant-time string comparison to prevent timing attacks.
    def secure_compare(a, b)
      return false unless a.bytesize == b.bytesize

      OpenSSL.fixed_length_secure_compare(a, b)
    rescue ArgumentError
      false
    end
  end
end
