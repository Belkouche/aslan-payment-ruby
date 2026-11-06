# frozen_string_literal: true

require_relative "../http"

module AslanPayment
  class Refunds
    # @param config [AslanPayment::Configuration]
    def initialize(config)
      @config = config
    end

    # Create a refund for a transaction.
    #
    # @param transaction_id [String] the transaction to refund
    # @param amount [Integer] refund amount in centimes
    # @param reason [String, nil] refund reason
    # @param idempotency_key [String, nil]
    # @return [Hash] refund object
    # @raise [AslanPayment::Error]
    def create(transaction_id:, amount:, reason: nil, idempotency_key: nil)
      headers = {}
      headers["Idempotency-Key"] = idempotency_key if idempotency_key

      body = {
        transactionId: transaction_id,
        amount: amount,
      }
      body[:reason] = reason if reason

      Http.unwrap(Http.request(
        method: :post,
        path: "/api/v1/refunds",
        config: @config,
        body: body,
        headers: headers
      ))
    end

    # Retrieve a refund by ID.
    #
    # @param id [String] refund ID
    # @return [Hash] refund object
    # @raise [AslanPayment::Error]
    def retrieve(id)
      Http.unwrap(Http.request(
        method: :get,
        path: "/api/v1/refunds/#{URI.encode_www_form_component(id)}",
        config: @config
      ))
    end

    # List refunds with optional filters.
    #
    # @param status [String, nil] filter by status
    # @param transaction_id [String, nil] filter by transaction ID
    # @param page [Integer, nil] page number
    # @param page_size [Integer, nil] items per page
    # @return [Hash] paginated response
    # @raise [AslanPayment::Error]
    def list(status: nil, transaction_id: nil, page: nil, page_size: nil)
      query = {}
      query["status"] = status if status
      query["transactionId"] = transaction_id if transaction_id
      query["page"] = page if page
      query["pageSize"] = page_size if page_size

      Http.request(
        method: :get,
        path: "/api/v1/refunds",
        config: @config,
        query: query
      )
    end
  end
end
