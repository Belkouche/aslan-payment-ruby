# Aslan Payment Ruby SDK

Official Ruby client for the [Aslan Payment API](https://doc.aslanpay.ma).

Zero external dependencies -- uses only Ruby standard library (`net/http`, `openssl`, `json`).

## Installation

Add to your Gemfile:

```ruby
gem "aslan_payment", git: "https://github.com/Belkouche/aslan-payment-ruby.git"
```

Then run:

```bash
bundle install
```

## Quick Start

```ruby
require "aslan_payment"

client = AslanPayment::Client.new(secret_key: "sk_test_xxx")

# Create a checkout session
session = client.checkout_sessions.create(
  amount: 15000,
  success_url: "https://example.com/success",
  cancel_url: "https://example.com/cancel"
)
puts session["url"] # Redirect your customer here
```

## Usage

### Initialize the Client

```ruby
client = AslanPayment::Client.new(
  secret_key: "sk_live_xxx",       # Required. Must start with sk_live_ or sk_test_
  base_url: "https://api.aslanpay.ma/pay", # Optional. Default shown
  timeout: 30,                     # Optional. Seconds. Default: 30
  max_retries: 2                   # Optional. Retries on 5xx/network errors. Default: 2
)

client.test_mode? # => false (true if using sk_test_*)
```

### Checkout Sessions

```ruby
# Create a checkout session
session = client.checkout_sessions.create(
  amount: 15000,                   # Amount in centimes (15000 = 150.00 MAD)
  currency: "MAD",                 # Optional, default: "MAD"
  success_url: "https://example.com/success",
  cancel_url: "https://example.com/cancel",
  customer: {
    email: "customer@example.com",
    name: "Ahmed B.",
    phone: "+212600000001"
  },
  metadata: { "order_id" => "ord_123" },
  idempotency_key: "unique-key-123" # Optional
)

# Process on an additional PSP account (alias); omit or use "default" for the default account.
# Also supported by payment_links.create. Responses carry "providerAccount".
session = client.checkout_sessions.create(
  amount: 10_000,
  success_url: "https://example.com/success",
  cancel_url: "https://example.com/cancel",
  provider_account: "foreign"
)

# Retrieve a checkout session
session = client.checkout_sessions.retrieve("cs_xxx")
```

### Transactions

```ruby
# Retrieve a transaction
txn = client.transactions.retrieve("txn_xxx")

# List transactions with filters
result = client.transactions.list(
  page: 1,
  page_size: 10,
  status: "succeeded",
  from: "2025-01-01T00:00:00Z",
  to: "2025-12-31T23:59:59Z",
  sort_by: "created_at",
  sort_order: "desc"
)
result["data"].each { |t| puts t["id"] }
puts result["pagination"]["total"]
```

### Payment Links

```ruby
# Create a payment link
link = client.payment_links.create(
  amount: 15000,
  description: "Order #123",
  max_payments: 1,
  expires_at: "2025-12-31T23:59:59Z",
  metadata: { "ref" => "abc" }
)
puts link["url"]

# Retrieve a payment link
link = client.payment_links.retrieve("pl_xxx")

# List payment links
result = client.payment_links.list(page: 1, status: "active")
```

### Refunds

```ruby
# Create a refund
refund = client.refunds.create(
  transaction_id: "txn_xxx",
  amount: 5000,                    # Partial refund: 50.00 MAD
  reason: "Customer request"
)

# Retrieve a refund
refund = client.refunds.retrieve("rf_xxx")
```

### Webhook Verification

```ruby
webhooks = AslanPayment::Webhooks.new("whsec_xxx")

# In your webhook endpoint (e.g., Rails controller)
payload = request.body.read
signature = request.headers["Aslan-Signature"]

begin
  event = webhooks.verify(payload, signature, tolerance: 300)
  case event["type"]
  when "checkout.completed"
    puts "Payment received: #{event["data"]["transaction_id"]}"
  when "refund.succeeded"
    puts "Refund processed: #{event["data"]["refund_id"]}"
  end
rescue AslanPayment::Error => e
  puts "Webhook verification failed: #{e.message}"
end
```

## Error Handling

All API errors raise `AslanPayment::Error`:

```ruby
begin
  client.transactions.retrieve("txn_nonexistent")
rescue AslanPayment::Error => e
  e.message     # "Transaction not found"
  e.code        # "NOT_FOUND"
  e.http_status # 404
  e.details     # Additional error details (Hash or nil)
  e.request_id  # Request ID for support (String or nil)
end
```

### Error Codes

| Code | Description |
|------|-------------|
| `AUTHENTICATION_ERROR` | Invalid or missing API key |
| `AUTHORIZATION_ERROR` | Insufficient permissions |
| `VALIDATION_ERROR` | Invalid request parameters |
| `NOT_FOUND` | Resource not found |
| `RATE_LIMITED` | Too many requests |
| `IDEMPOTENCY_ERROR` | Idempotency key conflict |
| `NETWORK_ERROR` | Connection or timeout failure |
| `SERVER_ERROR` | Server-side error (5xx) |
| `PROVIDER_ACCOUNT_NOT_FOUND` | `provider_account` names no account of your merchant |
| `PROVIDER_ACCOUNT_INACTIVE` | The `provider_account` is deactivated |
| `PROVIDER_ACCOUNT_UNSUPPORTED` | The account's provider cannot take this request |
| `PROVIDER_ACCOUNT_RECURRING_DISABLED` | The account does not allow recurring payments |

## Automatic Retries

The SDK automatically retries requests on transient failures (HTTP 408, 429, 500, 502, 503, 504) and network errors, with exponential backoff (500ms, 1s, 2s, ..., max 5s). Configure with `max_retries` (default: 2).

## Security

- Secret keys are sent via `Authorization: Bearer` header over HTTPS
- Webhook signatures use HMAC-SHA256 with constant-time comparison
- Never log or expose your secret key
- Use `sk_test_*` keys in development, `sk_live_*` in production

## Requirements

- Ruby >= 3.0
- No external dependencies

## License

MIT License. Copyright (c) 2025 Aslan.
