# frozen_string_literal: true

require_relative "../http"

module AslanPayment
  class PaymentLinks
    # @param config [AslanPayment::Configuration]
    def initialize(config)
      @config = config
    end

    # Create a new payment link.
    #
    # @param amount [Integer, nil] amount in centimes (nil for open-amount links)
    # @param currency [String] currency code (default: "MAD")
    # @param description [String, nil]
    # @param min_amount [Integer, nil] minimum amount for open-amount links
    # @param max_amount [Integer, nil] maximum amount for open-amount links
    # @param vendor_id [String, nil] vendor ID for marketplace payments
    # @param max_payments [Integer, nil] maximum number of payments
    # @param expires_at [String, Time, nil] expiration date
    # @param provider_account [String, nil] alias of an additional PSP account (omit or "default" for the default account)
    # @param metadata [Hash, nil] key-value metadata
    # @param idempotency_key [String, nil]
    # @return [Hash] payment link object
    # @raise [AslanPayment::Error]
    def create(amount: nil, currency: "MAD", description: nil, min_amount: nil,
               max_amount: nil, vendor_id: nil, provider_account: nil, max_payments: nil,
               expires_at: nil, metadata: nil, idempotency_key: nil)
      headers = {}
      headers["Idempotency-Key"] = idempotency_key if idempotency_key

      body = { currency: currency }
      body[:amount] = amount unless amount.nil?
      body[:description] = description if description
      body[:min_amount] = min_amount unless min_amount.nil?
      body[:max_amount] = max_amount unless max_amount.nil?
      body[:vendor_id] = vendor_id if vendor_id
      body[:providerAccount] = provider_account if provider_account
      body[:max_payments] = max_payments if max_payments
      body[:expires_at] = expires_at.is_a?(Time) ? expires_at.iso8601 : expires_at if expires_at
      body[:metadata] = metadata if metadata

      Http.request(
        method: :post,
        path: "/api/v1/payment-links",
        config: @config,
        body: body,
        headers: headers
      )
    end

    # Retrieve a payment link by ID.
    #
    # @param id [String] payment link ID
    # @return [Hash] payment link object
    # @raise [AslanPayment::Error]
    def retrieve(id)
      Http.request(
        method: :get,
        path: "/api/v1/payment-links/#{URI.encode_www_form_component(id)}",
        config: @config
      )
    end

    # List payment links with optional filters.
    #
    # @param page [Integer, nil]
    # @param page_size [Integer, nil]
    # @param status [String, nil] "active", "inactive", or "expired"
    # @return [Hash] paginated response
    # @raise [AslanPayment::Error]
    def list(page: nil, page_size: nil, status: nil)
      query = {}
      query["page"] = page if page
      query["page_size"] = page_size if page_size
      query["status"] = status if status

      Http.request(
        method: :get,
        path: "/api/v1/payment-links",
        config: @config,
        query: query
      )
    end

    # Update a payment link.
    #
    # @param id [String] payment link ID
    # @param description [String, nil] updated description
    # @param status [String, nil] "active" or "inactive"
    # @param max_payments [Integer, nil] updated max payments
    # @param expires_at [String, Time, nil] updated expiration date
    # @param metadata [Hash, nil] updated metadata
    # @return [Hash] updated payment link object
    # @raise [AslanPayment::Error]
    def update(id, description: nil, max_payments: nil, expires_at: nil,
               status: nil, metadata: nil)
      body = {}
      body[:description] = description if description
      body[:status] = status if status
      body[:maxPayments] = max_payments if max_payments
      body[:expiresAt] = expires_at.is_a?(Time) ? expires_at.iso8601 : expires_at if expires_at
      body[:metadata] = metadata if metadata

      Http.request(
        method: :patch,
        path: "/api/v1/payment-links/#{URI.encode_www_form_component(id)}",
        config: @config,
        body: body
      )
    end

    # Delete a payment link.
    #
    # @param id [String] payment link ID
    # @return [nil]
    # @raise [AslanPayment::Error]
    def delete(id)
      Http.request(
        method: :delete,
        path: "/api/v1/payment-links/#{URI.encode_www_form_component(id)}",
        config: @config
      )
      nil
    end

    # Get the QR code for a payment link.
    #
    # @param id [String] payment link ID
    # @param format [String, nil] QR code format (e.g., "png", "svg")
    # @param size [Integer, nil] QR code size in pixels
    # @return [Hash] QR code data
    # @raise [AslanPayment::Error]
    def get_qr(id, format: nil, size: nil)
      query = {}
      query["format"] = format if format
      query["size"] = size if size

      result = Http.request(
        method: :get,
        path: "/api/v1/payment-links/#{URI.encode_www_form_component(id)}/qr",
        config: @config,
        query: query
      )
      result["data"] || result
    end
  end
end
