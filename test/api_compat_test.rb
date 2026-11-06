# frozen_string_literal: true

require "minitest/autorun"
require "webmock/minitest"
require "aslan_payment"

# Wire-level contract tests against the aslan-payment-api shapes (stubbed HTTP).
class ApiCompatTest < Minitest::Test
  BASE = "https://api.aslanpay.ma/pay/api/v1"

  def client
    @client ||= AslanPayment::Client.new(secret_key: "sk_test_x", max_retries: 0)
  end

  def json(body, status: 200)
    { status: status, body: JSON.generate(body), headers: { "Content-Type" => "application/json" } }
  end

  # Stub a request, capture its JSON body, return the parsed body after the block.
  def capture(method, path, response)
    captured = nil
    stub_request(method, "#{BASE}#{path}")
      .with { |req| captured = req.body.to_s.empty? ? nil : JSON.parse(req.body); true }
      .to_return(response)
    result = yield
    [captured, result]
  end

  # --- request bodies -------------------------------------------------------

  def test_checkout_session_body_is_camel_case
    body, session = capture(:post, "/checkout/sessions", json({ "id" => "cs_1", "url" => "https://pay" }, status: 201)) do
      client.checkout_sessions.create(
        amount: 10_000, success_url: "https://a.ma/s", cancel_url: "https://a.ma/c",
        customer: { email: "a@b.ma", phone_country_code: "+212" },
        billing_address: { line1: "1 rue", postal_code: "20000" },
        shipping_address: { recipient_name: "Ahmed" },
        line_items: [{ name: "Tea", quantity: 1, unit_price: 10_000, seller_id: "s1" }],
        sellers: [{ id: "s1", name: "S", commission_rate: 500, fixed_fee: 0, metadata: { "my_key" => "v" } }],
        browser_info: { user_agent: "UA", screen_width: 1280 },
        vendor_id: "11111111-1111-1111-1111-111111111111",
        metadata: { "order_id" => "o1" }
      )
    end

    assert_equal "https://a.ma/s", body["successUrl"]
    assert_equal "https://a.ma/c", body["cancelUrl"]
    assert_equal "+212", body["customer"]["phoneCountryCode"]
    assert_equal "20000", body["billingAddress"]["postalCode"]
    assert_equal "Ahmed", body["shippingAddress"]["recipientName"]
    assert_equal({ "name" => "Tea", "quantity" => 1, "unitPrice" => 10_000, "sellerId" => "s1" }, body["lineItems"][0])
    assert_equal 500, body["sellers"][0]["commissionRate"]
    assert_equal({ "my_key" => "v" }, body["sellers"][0]["metadata"], "metadata keys are user-defined")
    assert_equal({ "userAgent" => "UA", "screenWidth" => 1280 }, body["browserInfo"])
    assert_equal "11111111-1111-1111-1111-111111111111", body["vendorId"]
    assert_equal({ "order_id" => "o1" }, body["metadata"])
    refute(body.keys.any? { |k| k.include?("_") }, "no snake_case top-level keys: #{body.keys}")
    assert_equal "cs_1", session["id"], "checkout sessions are returned unwrapped"
  end

  def test_refund_body_and_unwrap
    body, refund = capture(:post, "/refunds", json({ "data" => { "id" => "rf_1" } }, status: 201)) do
      client.refunds.create(transaction_id: "t1", amount: 500, reason: "r")
    end
    assert_equal({ "transactionId" => "t1", "amount" => 500, "reason" => "r" }, body)
    assert_equal "rf_1", refund["id"]
  end

  def test_payment_link_create_body_and_unwrap
    body, link = capture(:post, "/payment-links", json({ "data" => { "id" => "pl_1" } }, status: 201)) do
      client.payment_links.create(min_amount: 100, max_amount: 900, vendor_id: "v1", max_payments: 3,
                                  expires_at: "2027-01-01T00:00:00Z")
    end
    assert_equal({ "currency" => "MAD", "minAmount" => 100, "maxAmount" => 900, "vendorId" => "v1",
                   "maxPayments" => 3, "expiresAt" => "2027-01-01T00:00:00Z" }, body)
    assert_equal "pl_1", link["id"]
  end

  def test_vendor_create_and_update_bodies
    body, vendor = capture(:post, "/vendors", json({ "data" => { "id" => "v1" } })) do
      client.vendors.create(name: "V", external_id: "x", commission_rate: 0.05)
    end
    assert_equal({ "name" => "V", "externalId" => "x", "commissionRate" => 0.05 }, body)
    assert_equal "v1", vendor["id"]

    body, vendor = capture(:patch, "/vendors/v1", json({ "data" => { "id" => "v1", "isActive" => false } })) do
      client.vendors.update("v1", commission_rate: 0.1, external_id: "y", is_active: false)
    end
    assert_equal({ "commissionRate" => 0.1, "externalId" => "y", "isActive" => false }, body)
    assert_equal false, vendor["isActive"]
  end

  # --- query params ---------------------------------------------------------

  def test_list_query_params_are_camel_case
    list = json({ "data" => [], "pagination" => { "total" => 0 } })
    stub_request(:get, "#{BASE}/transactions")
      .with(query: { "page" => "1", "pageSize" => "10", "sortBy" => "createdAt", "sortOrder" => "asc" }).to_return(list)
    stub_request(:get, "#{BASE}/customers")
      .with(query: { "pageSize" => "5", "sortBy" => "email", "sortOrder" => "desc" }).to_return(list)
    stub_request(:get, "#{BASE}/payment-links").with(query: { "pageSize" => "7" }).to_return(list)
    stub_request(:get, "#{BASE}/vendors").with(query: { "isActive" => "true", "limit" => "2" }).to_return(list)
    stub_request(:get, "#{BASE}/refunds")
      .with(query: { "transactionId" => "t1", "pageSize" => "3" }).to_return(list)

    result = client.transactions.list(page: 1, page_size: 10, sort_by: "created_at", sort_order: "asc")
    assert_equal({ "total" => 0 }, result["pagination"], "lists keep { data, pagination }")
    client.customers.list(page_size: 5, sort_by: "email", sort_order: "desc")
    client.payment_links.list(page_size: 7)
    client.vendors.list(is_active: true, limit: 2)
    client.refunds.list(transaction_id: "t1", page_size: 3)
  end

  # --- response unwrap ------------------------------------------------------

  def test_single_object_responses_are_unwrapped
    stub_request(:get, "#{BASE}/transactions/t1").to_return(json({ "data" => { "id" => "t1", "createdAt" => "x" } }))
    stub_request(:get, "#{BASE}/customers/c1").to_return(json({ "data" => { "id" => "c1" } }))
    stub_request(:get, "#{BASE}/refunds/r1").to_return(json({ "data" => { "id" => "r1" } }))
    stub_request(:get, "#{BASE}/payment-links/p1").to_return(json({ "data" => { "id" => "p1" } }))
    stub_request(:patch, "#{BASE}/payment-links/p1").to_return(json({ "data" => { "id" => "p1" } }))
    stub_request(:get, "#{BASE}/vendors/v1").to_return(json({ "data" => { "id" => "v1" } }))
    stub_request(:delete, "#{BASE}/vendors/v1").to_return(json({ "data" => { "id" => "v1" } }))
    stub_request(:get, "#{BASE}/checkout/sessions/cs_1").to_return(json({ "id" => "cs_1" }))
    stub_request(:post, "#{BASE}/api-keys").to_return(json({ "data" => { "id" => "k1" } }, status: 201))
    stub_request(:get, "#{BASE}/webhooks/config").to_return(json({ "data" => { "url" => "https://h" } }))
    stub_request(:post, "#{BASE}/webhooks/config").to_return(json({ "data" => { "url" => "https://h" } }))

    assert_equal "t1", client.transactions.retrieve("t1")["id"]
    assert_equal "c1", client.customers.retrieve("c1")["id"]
    assert_equal "r1", client.refunds.retrieve("r1")["id"]
    assert_equal "p1", client.payment_links.retrieve("p1")["id"]
    assert_equal "p1", client.payment_links.update("p1", description: "d")["id"]
    assert_equal "v1", client.vendors.retrieve("v1")["id"]
    assert_equal "v1", client.vendors.delete("v1")["id"]
    assert_equal "cs_1", client.checkout_sessions.retrieve("cs_1")["id"]
    assert_equal "k1", client.api_keys.create(name: "n", type: "test")["id"]
    assert_equal "https://h", client.webhooks_config.retrieve["url"]
    assert_equal "https://h", client.webhooks_config.update(url: "https://h")["url"]
  end

  # --- errors ---------------------------------------------------------------

  def test_flat_error_body
    stub_request(:get, "#{BASE}/transactions/t1").to_return(
      json({ "statusCode" => 401, "code" => "INVALID_API_KEY", "error" => "Unauthorized", "message" => "Invalid API key" },
           status: 401)
    )
    err = assert_raises(AslanPayment::Error) { client.transactions.retrieve("t1") }
    assert_equal "AUTHENTICATION_ERROR", err.code
    assert_equal "Invalid API key", err.message
    assert_equal 401, err.http_status
  end

  def test_flat_error_with_details_and_server_code
    details = [{ "field" => "successUrl", "message" => "Required" }]
    stub_request(:post, "#{BASE}/refunds").to_return(
      json({ "statusCode" => 400, "code" => "PROVIDER_ACCOUNT_INACTIVE", "error" => "Bad Request",
             "message" => "inactive", "details" => details }, status: 400)
    )
    err = assert_raises(AslanPayment::Error) { client.refunds.create(transaction_id: "t1", amount: 1) }
    assert_equal "PROVIDER_ACCOUNT_INACTIVE", err.code
    assert_equal details, err.details
  end

  def test_nested_error_body
    stub_request(:get, "#{BASE}/vendors/v1").to_return(
      json({ "error" => { "code" => "VALIDATION_ERROR", "message" => "Bad", "details" => [{ "field" => "x" }] } },
           status: 400)
    )
    err = assert_raises(AslanPayment::Error) { client.vendors.retrieve("v1") }
    assert_equal "VALIDATION_ERROR", err.code
    assert_equal "Bad", err.message
    assert_equal [{ "field" => "x" }], err.details
  end
end
