# frozen_string_literal: true

require_relative "../http"

module AslanPayment
  class ApiKeys
    # @param config [AslanPayment::Configuration]
    def initialize(config)
      @config = config
    end

    # Create a new API key.
    #
    # @param name [String] key name
    # @param type [String] key type (e.g., "live" or "test")
    # @param idempotency_key [String, nil] idempotency key
    # @return [Hash] API key object
    # @raise [AslanPayment::Error]
    def create(name:, type:, idempotency_key: nil)
      headers = {}
      headers["Idempotency-Key"] = idempotency_key if idempotency_key

      body = {
        name: name,
        type: type,
      }

      Http.unwrap(Http.request(
        method: :post,
        path: "/api/v1/api-keys",
        config: @config,
        body: body,
        headers: headers
      ))
    end

    # List all API keys.
    #
    # @return [Hash] list of API key objects
    # @raise [AslanPayment::Error]
    def list
      Http.request(
        method: :get,
        path: "/api/v1/api-keys",
        config: @config
      )
    end

    # Delete an API key.
    #
    # @param id [String] API key ID
    # @return [nil]
    # @raise [AslanPayment::Error]
    def delete(id)
      Http.request(
        method: :delete,
        path: "/api/v1/api-keys/#{URI.encode_www_form_component(id)}",
        config: @config
      )
      nil
    end
  end
end
