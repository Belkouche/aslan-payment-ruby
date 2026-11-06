# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require_relative "error"
require_relative "version"

module AslanPayment
  # Low-level HTTP client with retries and exponential backoff.
  # Uses only net/http from the standard library.
  module Http
    RETRYABLE_STATUS_CODES = [408, 429, 500, 502, 503, 504].freeze
    USER_AGENT = "aslan-payment-ruby/#{VERSION}"

    module_function

    # Perform an HTTP request with automatic retries on transient failures.
    #
    # @param method [Symbol] :get, :post, :patch, :delete
    # @param path [String] API path (e.g. "/api/v1/transactions")
    # @param config [AslanPayment::Configuration]
    # @param body [Hash, nil] request body (JSON-encoded)
    # @param query [Hash, nil] query string parameters
    # @param headers [Hash] additional headers
    # @return [Hash, nil] parsed JSON response
    # @raise [AslanPayment::Error]
    def request(method:, path:, config:, body: nil, query: nil, headers: {})
      uri = build_uri(config.base_url, path, query)
      last_error = nil

      (0..config.max_retries).each do |attempt|
        if attempt > 0
          delay = [0.5 * (2**(attempt - 1)), 5.0].min
          sleep(delay)
        end

        begin
          response = execute_request(method, uri, config, body, headers)
          request_id = response["x-request-id"]

          # Retry on transient errors
          if RETRYABLE_STATUS_CODES.include?(response.code.to_i) && attempt < config.max_retries
            last_error = Error.new(
              "SERVER_ERROR",
              "Request failed with status #{response.code}",
              http_status: response.code.to_i,
              request_id: request_id
            )
            next
          end

          # 204 No Content
          return nil if response.code.to_i == 204

          # Parse JSON
          json = begin
            JSON.parse(response.body)
          rescue JSON::ParserError
            raise Error.new(
              "SERVER_ERROR",
              "Unexpected response from server (#{response.code})",
              http_status: response.code.to_i,
              request_id: request_id
            )
          end

          # Error responses
          unless response.is_a?(Net::HTTPSuccess)
            # Flat { statusCode, code, error, message, details? } or nested { error: { code, message, details? } }
            error_body = json.is_a?(Hash) ? (json["error"].is_a?(Hash) ? json["error"] : json) : {}
            code = Error.code_for_status(response.code.to_i, error_body["code"])
            raise Error.new(
              code,
              error_body["message"] || "Request failed with status #{response.code}",
              http_status: response.code.to_i,
              details: error_body["details"],
              request_id: request_id
            )
          end

          return json

        rescue Error
          raise
        rescue Timeout::Error, Errno::ETIMEDOUT
          last_error = Error.new("NETWORK_ERROR", "Request timed out")
          next if attempt < config.max_retries
        rescue SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET, EOFError, IOError => e
          last_error = Error.new("NETWORK_ERROR", "Network request failed: #{e.message}")
          next if attempt < config.max_retries
        end
      end

      raise last_error || Error.new("NETWORK_ERROR", "Request failed after retries")
    end

    # Unwrap a `{ "data": X }` envelope, returning X (other responses unchanged).
    # @api private
    def unwrap(json)
      json.is_a?(Hash) && json.key?("data") ? json["data"] : json
    end

    # snake_case -> camelCase ("success_url" -> "successUrl"; already-camel names unchanged).
    # @api private
    def camelize(key)
      key.to_s.gsub(/_([a-z\d])/) { Regexp.last_match(1).upcase }
    end

    # Deep-camelize Hash keys for the wire. "metadata" values are user-defined and left as-is.
    # @api private
    def camelize_keys(obj)
      case obj
      when Hash
        obj.each_with_object({}) do |(k, v), h|
          key = camelize(k)
          h[key] = key == "metadata" ? v : camelize_keys(v)
        end
      when Array then obj.map { |v| camelize_keys(v) }
      else obj
      end
    end

    # @api private
    def build_uri(base_url, path, query)
      uri = URI.join(base_url.chomp("/") + "/", path.sub(%r{^/}, ""))
      if query
        params = query.reject { |_, v| v.nil? }.map { |k, v| "#{URI.encode_www_form_component(k)}=#{URI.encode_www_form_component(v.to_s)}" }
        uri.query = params.join("&") unless params.empty?
      end
      uri
    end

    # @api private
    def execute_request(method, uri, config, body, extra_headers)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = config.timeout
      http.read_timeout = config.timeout

      request_class = case method
                      when :get    then Net::HTTP::Get
                      when :post   then Net::HTTP::Post
                      when :patch  then Net::HTTP::Patch
                      when :delete then Net::HTTP::Delete
                      else raise ArgumentError, "Unsupported HTTP method: #{method}"
                      end

      req = request_class.new(uri)
      req["Content-Type"] = "application/json"
      req["Authorization"] = "Bearer #{config.secret_key}"
      req["User-Agent"] = USER_AGENT
      extra_headers.each { |k, v| req[k] = v }
      req.body = JSON.generate(body) if body

      http.request(req)
    end
  end
end
