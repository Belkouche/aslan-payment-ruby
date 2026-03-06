# frozen_string_literal: true

module AslanPayment
  class Configuration
    DEFAULT_BASE_URL = "https://api.aslanpay.ma/pay"
    DEFAULT_TIMEOUT = 30
    DEFAULT_MAX_RETRIES = 2

    attr_accessor :secret_key, :base_url, :timeout, :max_retries

    def initialize(secret_key:, base_url: nil, timeout: nil, max_retries: nil)
      @secret_key = secret_key
      @base_url = base_url || DEFAULT_BASE_URL
      @timeout = timeout || DEFAULT_TIMEOUT
      @max_retries = max_retries || DEFAULT_MAX_RETRIES
    end
  end
end
