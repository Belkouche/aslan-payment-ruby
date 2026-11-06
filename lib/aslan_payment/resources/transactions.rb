# frozen_string_literal: true

require_relative "../http"

module AslanPayment
  class Transactions
    # @param config [AslanPayment::Configuration]
    def initialize(config)
      @config = config
    end

    # Retrieve a transaction by ID.
    #
    # @param id [String] transaction ID
    # @return [Hash] transaction object
    # @raise [AslanPayment::Error]
    def retrieve(id)
      Http.unwrap(Http.request(
        method: :get,
        path: "/api/v1/transactions/#{URI.encode_www_form_component(id)}",
        config: @config
      ))
    end

    # List transactions with optional filters.
    #
    # @param page [Integer, nil] page number
    # @param page_size [Integer, nil] items per page
    # @param status [String, nil] filter by status
    # @param from [String, Time, nil] start date filter
    # @param to [String, Time, nil] end date filter
    # @param sort_by [String, nil] sort field ("createdAt"/"created_at", "amount", "status")
    # @param sort_order [String, nil] "asc" or "desc"
    # @return [Hash] paginated response with :data and :pagination
    # @raise [AslanPayment::Error]
    def list(page: nil, page_size: nil, status: nil, from: nil, to: nil,
             sort_by: nil, sort_order: nil)
      query = {}
      query["page"] = page if page
      query["pageSize"] = page_size if page_size
      query["status"] = status if status
      query["from"] = from.is_a?(Time) ? from.iso8601 : from if from
      query["to"] = to.is_a?(Time) ? to.iso8601 : to if to
      query["sortBy"] = Http.camelize(sort_by) if sort_by
      query["sortOrder"] = sort_order if sort_order

      Http.request(
        method: :get,
        path: "/api/v1/transactions",
        config: @config,
        query: query
      )
    end
  end
end
