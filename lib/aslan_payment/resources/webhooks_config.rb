# frozen_string_literal: true

require_relative "../http"

module AslanPayment
  class WebhooksConfig
    # @param config [AslanPayment::Configuration]
    def initialize(config)
      @config = config
    end

    # Update the webhook configuration.
    #
    # @param url [String] webhook endpoint URL
    # @param events [Array<String>, nil] list of event types to subscribe to
    # @return [Hash] webhook config object
    # @raise [AslanPayment::Error]
    def update(url:, events: nil)
      body = { url: url }
      body[:events] = events if events

      Http.unwrap(Http.request(
        method: :post,
        path: "/api/v1/webhooks/config",
        config: @config,
        body: body
      ))
    end

    # Retrieve the current webhook configuration.
    #
    # @return [Hash] webhook config object
    # @raise [AslanPayment::Error]
    def retrieve
      Http.unwrap(Http.request(
        method: :get,
        path: "/api/v1/webhooks/config",
        config: @config
      ))
    end
  end
end
