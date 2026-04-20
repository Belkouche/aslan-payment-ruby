# frozen_string_literal: true

require_relative "configuration"
require_relative "error"
require_relative "resources/checkout_sessions"
require_relative "resources/transactions"
require_relative "resources/payment_links"
require_relative "resources/refunds"
require_relative "resources/webhooks"
require_relative "resources/vendors"
require_relative "resources/customers"
require_relative "resources/api_keys"
require_relative "resources/webhooks_config"

module AslanPayment
  class Client
    # @return [AslanPayment::CheckoutSessions]
    attr_reader :checkout_sessions

    # @return [AslanPayment::Transactions]
    attr_reader :transactions

    # @return [AslanPayment::PaymentLinks]
    attr_reader :payment_links

    # @return [AslanPayment::Refunds]
    attr_reader :refunds

    # @return [AslanPayment::Vendors]
    attr_reader :vendors

    # @return [AslanPayment::Customers]
    attr_reader :customers

    # @return [AslanPayment::ApiKeys]
    attr_reader :api_keys

    # @return [AslanPayment::WebhooksConfig]
    attr_reader :webhooks_config

    # Create a new Aslan Payment API client.
    #
    # @param secret_key [String] API secret key (must start with sk_live_ or sk_test_)
    # @param base_url [String, nil] API base URL (default: https://api.aslanpay.ma/pay)
    # @param timeout [Integer, nil] request timeout in seconds (default: 30)
    # @param max_retries [Integer, nil] max retries on 5xx/network errors (default: 2)
    # @raise [AslanPayment::Error] if secret_key format is invalid
    def initialize(secret_key:, base_url: nil, timeout: nil, max_retries: nil)
      unless secret_key.start_with?("sk_live_") || secret_key.start_with?("sk_test_")
        raise Error.new(
          "AUTHENTICATION_ERROR",
          "Invalid secret key format. Must start with sk_live_ or sk_test_"
        )
      end

      @config = Configuration.new(
        secret_key: secret_key,
        base_url: base_url,
        timeout: timeout,
        max_retries: max_retries
      )

      @checkout_sessions = CheckoutSessions.new(@config)
      @transactions = Transactions.new(@config)
      @payment_links = PaymentLinks.new(@config)
      @refunds = Refunds.new(@config)
      @vendors = Vendors.new(@config)
      @customers = Customers.new(@config)
      @api_keys = ApiKeys.new(@config)
      @webhooks_config = WebhooksConfig.new(@config)
    end

    # Whether the client is using a test mode key.
    #
    # @return [Boolean]
    def test_mode?
      @config.secret_key.start_with?("sk_test_")
    end
  end
end
