# frozen_string_literal: true

require_relative "../http"

module AslanPayment
  class Vendors
    # @param config [AslanPayment::Configuration]
    def initialize(config)
      @config = config
    end

    # Create a new vendor.
    #
    # @param name [String] vendor name
    # @param external_id [String, nil] external identifier
    # @param email [String, nil] vendor email
    # @param commission_rate [Float, nil] commission rate (e.g., 0.05 for 5%)
    # @param metadata [Hash, nil] key-value metadata
    # @param idempotency_key [String, nil] idempotency key
    # @return [Hash] vendor object
    # @raise [AslanPayment::Error]
    def create(name:, external_id: nil, email: nil, commission_rate: nil, metadata: nil, idempotency_key: nil)
      headers = {}
      headers["Idempotency-Key"] = idempotency_key if idempotency_key

      body = { name: name }
      body[:externalId] = external_id if external_id
      body[:email] = email if email
      body[:commissionRate] = commission_rate unless commission_rate.nil?
      body[:metadata] = metadata if metadata

      Http.unwrap(Http.request(
        method: :post,
        path: "/api/v1/vendors",
        config: @config,
        body: body,
        headers: headers
      ))
    end

    # Retrieve a vendor by ID.
    #
    # @param id [String] vendor ID
    # @return [Hash] vendor object
    # @raise [AslanPayment::Error]
    def retrieve(id)
      Http.unwrap(Http.request(
        method: :get,
        path: "/api/v1/vendors/#{URI.encode_www_form_component(id)}",
        config: @config
      ))
    end

    # List vendors with optional filters.
    #
    # @param page [Integer, nil] page number
    # @param limit [Integer, nil] items per page
    # @param search [String, nil] search term
    # @param is_active [Boolean, nil] filter by active status
    # @return [Hash] paginated response
    # @raise [AslanPayment::Error]
    def list(page: nil, limit: nil, search: nil, is_active: nil)
      query = {}
      query["page"] = page if page
      query["limit"] = limit if limit
      query["search"] = search if search
      query["isActive"] = is_active unless is_active.nil?

      Http.request(
        method: :get,
        path: "/api/v1/vendors",
        config: @config,
        query: query
      )
    end

    # Update a vendor.
    #
    # @param id [String] vendor ID
    # @param name [String, nil] updated name
    # @param email [String, nil] updated email
    # @param commission_rate [Float, nil] updated commission rate
    # @param external_id [String, nil] updated external identifier
    # @param is_active [Boolean, nil] updated active status
    # @param metadata [Hash, nil] updated metadata
    # @return [Hash] updated vendor object
    # @raise [AslanPayment::Error]
    def update(id, name: nil, email: nil, commission_rate: nil, external_id: nil, is_active: nil, metadata: nil)
      body = {}
      body[:name] = name if name
      body[:email] = email if email
      body[:commissionRate] = commission_rate unless commission_rate.nil?
      body[:externalId] = external_id if external_id
      body[:isActive] = is_active unless is_active.nil?
      body[:metadata] = metadata if metadata

      Http.unwrap(Http.request(
        method: :patch,
        path: "/api/v1/vendors/#{URI.encode_www_form_component(id)}",
        config: @config,
        body: body
      ))
    end

    # Delete (soft-delete) a vendor.
    #
    # @param id [String] vendor ID
    # @return [Hash] deleted vendor object
    # @raise [AslanPayment::Error]
    def delete(id)
      Http.unwrap(Http.request(
        method: :delete,
        path: "/api/v1/vendors/#{URI.encode_www_form_component(id)}",
        config: @config
      ))
    end
  end
end
