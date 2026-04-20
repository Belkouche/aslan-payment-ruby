# frozen_string_literal: true

require_relative "../http"

module AslanPayment
  class Customers
    # @param config [AslanPayment::Configuration]
    def initialize(config)
      @config = config
    end

    # List customers with optional filters.
    #
    # @param page [Integer, nil] page number
    # @param page_size [Integer, nil] items per page
    # @param search [String, nil] search term
    # @param sort_by [String, nil] sort field
    # @param sort_order [String, nil] "asc" or "desc"
    # @return [Hash] paginated response
    # @raise [AslanPayment::Error]
    def list(page: nil, page_size: nil, search: nil, sort_by: nil, sort_order: nil)
      query = {}
      query["page"] = page if page
      query["page_size"] = page_size if page_size
      query["search"] = search if search
      query["sort_by"] = sort_by if sort_by
      query["sort_order"] = sort_order if sort_order

      Http.request(
        method: :get,
        path: "/api/v1/customers",
        config: @config,
        query: query
      )
    end

    # Retrieve a customer by ID.
    #
    # @param id [String] customer ID
    # @return [Hash] customer object
    # @raise [AslanPayment::Error]
    def retrieve(id)
      Http.request(
        method: :get,
        path: "/api/v1/customers/#{URI.encode_www_form_component(id)}",
        config: @config
      )
    end
  end
end
