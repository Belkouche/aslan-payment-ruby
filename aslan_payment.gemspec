# frozen_string_literal: true

require_relative "lib/aslan_payment/version"

Gem::Specification.new do |spec|
  spec.name = "aslan_payment"
  spec.version = AslanPayment::VERSION
  spec.authors = ["Aslan"]
  spec.email = ["dev@aslanpay.ma"]

  spec.summary = "Ruby SDK for the Aslan Payment API"
  spec.description = "Official Ruby client for the Aslan Payment API. " \
                     "Accept payments, manage transactions, create payment links, " \
                     "process refunds, and verify webhooks."
  spec.homepage = "https://github.com/Belkouche/aslan-payment-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Belkouche/aslan-payment-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/Belkouche/aslan-payment-ruby/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://doc.aslanpay.ma"

  spec.files = Dir["lib/**/*.rb", "LICENSE", "README.md"]
  spec.require_paths = ["lib"]

  # Zero external dependencies - uses only Ruby stdlib (net/http, openssl, json, uri)
end
