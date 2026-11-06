# frozen_string_literal: true

require_relative "../http"

module AslanPayment
  class CheckoutSessions
    # @param config [AslanPayment::Configuration]
    def initialize(config)
      @config = config
    end

    # Create a new checkout session.
    #
    # @param amount [Integer] amount in centimes (100 = 1.00 MAD)
    # @param success_url [String] redirect URL on successful payment
    # @param cancel_url [String] redirect URL on cancellation
    # @param currency [String] currency code (default: "MAD")
    # @param customer [Hash, nil] customer details (:email, :name, :phone, :phone_country_code)
    # @param billing_address [Hash, nil] billing address
    # @param shipping_address [Hash, nil] shipping address
    # @param line_items [Array<Hash>, nil] line items
    # @param sellers [Array<Hash>, nil] seller split payment details
    # @param browser_info [Hash, nil] browser information for 3DS
    # @param require3ds [Boolean, nil] whether to require 3DS authentication
    # @param vendor_id [String, nil] vendor ID for marketplace payments
    # @param provider_account [String, nil] alias of an additional PSP account (omit or "default" for the default account)
    # @param metadata [Hash, nil] key-value metadata
    # @param idempotency_key [String, nil] idempotency key
    # @return [Hash] checkout session object
    # @raise [AslanPayment::Error]
    def create(amount:, success_url:, cancel_url:, currency: "MAD",
               customer: nil, billing_address: nil, shipping_address: nil,
               line_items: nil, sellers: nil, browser_info: nil, require3ds: nil,
               vendor_id: nil, provider_account: nil, metadata: nil, idempotency_key: nil)
      headers = {}
      headers["Idempotency-Key"] = idempotency_key if idempotency_key

      body = {
        amount: amount,
        currency: currency,
        successUrl: success_url,
        cancelUrl: cancel_url,
      }
      # Nested hashes accept snake_case or camelCase keys (e.g. :phone_country_code, :unit_price).
      body[:customer] = Http.camelize_keys(customer) if customer
      body[:billingAddress] = Http.camelize_keys(billing_address) if billing_address
      body[:shippingAddress] = Http.camelize_keys(shipping_address) if shipping_address
      body[:lineItems] = Http.camelize_keys(line_items) if line_items
      body[:sellers] = Http.camelize_keys(sellers) if sellers
      body[:browserInfo] = Http.camelize_keys(browser_info) if browser_info
      body[:require3ds] = require3ds unless require3ds.nil?
      body[:vendorId] = vendor_id if vendor_id
      body[:providerAccount] = provider_account if provider_account
      body[:metadata] = metadata if metadata

      Http.request(
        method: :post,
        path: "/api/v1/checkout/sessions",
        config: @config,
        body: body,
        headers: headers
      )
    end

    # Retrieve a checkout session by ID.
    #
    # @param id [String] checkout session ID
    # @return [Hash] checkout session object
    # @raise [AslanPayment::Error]
    def retrieve(id)
      Http.request(
        method: :get,
        path: "/api/v1/checkout/sessions/#{URI.encode_www_form_component(id)}",
        config: @config
      )
    end
  end
end
