# frozen_string_literal: true

require "minitest/autorun"
require "aslan_payment"

class ProviderAccountTest < Minitest::Test
  def with_captured_body
    captured = nil
    AslanPayment::Http.singleton_class.send(:alias_method, :__orig_request, :request)
    AslanPayment::Http.define_singleton_method(:request) { |**kw| captured = kw[:body]; {} }
    yield
    captured
  ensure
    AslanPayment::Http.singleton_class.send(:alias_method, :request, :__orig_request)
    AslanPayment::Http.singleton_class.send(:remove_method, :__orig_request)
  end

  def config
    AslanPayment::Configuration.new(secret_key: "sk_test_x")
  end

  def test_checkout_session_sends_provider_account
    body = with_captured_body do
      AslanPayment::CheckoutSessions.new(config).create(
        amount: 10_000, success_url: "https://a.ma/s", cancel_url: "https://a.ma/c", provider_account: "foreign"
      )
    end
    assert_equal "foreign", body[:providerAccount]
  end

  def test_checkout_session_omits_provider_account_by_default
    body = with_captured_body do
      AslanPayment::CheckoutSessions.new(config).create(
        amount: 10_000, success_url: "https://a.ma/s", cancel_url: "https://a.ma/c"
      )
    end
    refute body.key?(:providerAccount)
  end

  def test_payment_link_sends_provider_account
    body = with_captured_body { AslanPayment::PaymentLinks.new(config).create(amount: 100, provider_account: "store-2") }
    assert_equal "store-2", body[:providerAccount]
  end

  def test_provider_account_error_codes_pass_through
    %w[NOT_FOUND INACTIVE UNSUPPORTED RECURRING_DISABLED].each do |s|
      code = "PROVIDER_ACCOUNT_#{s}"
      assert_equal code, AslanPayment::Error.code_for_status(400, code)
    end
  end
end
