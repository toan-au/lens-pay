# LensPay

A payment gateway API built with Ruby on Rails. Covers merchant onboarding, the full payment lifecycle, partial captures, refunds, and outbound webhook delivery.

Live demo: [lenspay.toanau.com](https://lenspay.toanau.com)  
API docs: `http://localhost:3000/api-docs`

---

## Stack

- **Ruby 4.0 / Rails 8.1**
- **PostgreSQL**
- **Solid Queue** (database-backed background jobs, no Redis)
- **AASM** (state machine for payment lifecycle)
- **rswag** (OpenAPI docs generated from RSpec integration specs)
- **Vue 3 + Pinia** (frontend)
- **RSpec + FactoryBot**

---

## Getting Started

**Prerequisites:** Ruby 4.0, PostgreSQL (or Docker)

```bash
git clone https://github.com/toan-au/lens-pay
cd lens-pay
bundle install
```

Start PostgreSQL:
```bash
docker-compose up -d
```

Set up the database:
```bash
bin/rails db:create db:migrate
```

Start the server:
```bash
bin/rails server
```

The frontend is at `http://localhost:3000`. API docs are at `http://localhost:3000/api-docs`.

---

## Running Tests

```bash
bundle exec rspec
```

To regenerate the OpenAPI spec after changing integration tests:
```bash
bundle exec rake rswag:specs:swaggerize
```

---

## API Overview

All endpoints except `POST /merchants` and `POST /webhook-captures/:merchant_uid` require `Authorization: Bearer <api_key>`.

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/merchants` | Register a merchant. Returns API key and webhook secret (shown once) |
| `GET` | `/api/v1/merchants/me` | Fetch merchant profile |
| `PATCH` | `/api/v1/merchants/me` | Update merchant profile |
| `POST` | `/api/v1/payments` | Create a payment |
| `GET` | `/api/v1/payments` | List payments (cursor pagination, status filter) |
| `GET` | `/api/v1/payments/:uid` | Fetch a payment |
| `POST` | `/api/v1/payments/:uid/capture` | Capture an authorized payment (supports partial capture) |
| `POST` | `/api/v1/payments/:payment_uid/refunds` | Create a refund |
| `GET` | `/api/v1/payments/:payment_uid/refunds` | List refunds for a payment |
| `GET` | `/api/v1/refunds` | List all refunds |
| `POST` | `/api/v1/webhook-captures/:merchant_uid` | Receive and store a signed webhook event (public) |
| `GET` | `/api/v1/webhook-captures` | List received webhook events for the authenticated merchant |

---

## Payment Lifecycle

```
pending -> authorized -> processing -> succeeded
pending/authorized/processing -> declined
```

Merchants create a payment via `POST /payments`. The lifecycle from there is processor-driven, not merchant-driven. LensPay simulates the processor with background jobs:

- **`AuthorizePaymentJob`** simulates card network authorization. Success: `pending -> authorized`. Failure: `pending -> declined`.
- **`SettlePaymentJob`** simulates settlement after capture. Success: `processing -> succeeded`. Failure: `processing -> declined`.
- **`ProcessRefundJob`** simulates refund processing. Success: `refund -> succeeded`. Failure: `refund -> declined`.

`POST /payments/:uid/capture` is the only merchant-facing state transition. Merchants control when funds move (typically at shipment, not at checkout). Everything else is processor-driven.

In a real gateway these jobs would be replaced by inbound webhooks from the card network.

---

## Webhook Delivery

After each async state transition, LensPay posts a signed JSON event to the merchant's `webhook_url`.

Every request includes an HMAC-SHA256 signature:

```
X-LensPay-Signature: sha256=<hex>
```

The signature is computed over the raw request body using the merchant's `webhook_secret`. Merchants verify it with a constant-time comparison.

**Events:** `payment.authorized`, `payment.succeeded`, `payment.declined`, `refund.succeeded`, `refund.declined`

Delivery runs in `WebhookDeliveryJob` on an isolated `:webhooks` queue so a slow merchant endpoint cannot back up payment processing. Failed deliveries retry with exponential backoff. After 3 attempts the failure is written to the audit log.

Each merchant's `webhook_url` is automatically set to `/api/v1/webhook-captures/:merchant_uid` on creation. This endpoint verifies the HMAC signature and stores the event. The frontend displays captured events on the Payment Detail page and the Webhooks index, so the full delivery loop is visible without an external server.

---

## Design Decisions

### Payment lifecycle as a state machine

AASM enforces valid transitions at the model level. Invalid transitions raise rather than silently fail. Each transition has a dedicated service object (`AuthorizeService`, `CaptureService`, `CompleteService`, `DeclineService`) rather than putting the logic in callbacks or the model itself.

### Partial capture

Each payment has a `captured_amount` column separate from `amount`. A merchant can capture less than the authorized amount (e.g. authorize 10,000 JPY, capture 8,000 JPY if one item is out of stock). Authorization reserves funds, capture moves them. Only one capture per transaction is supported, which matches the standard acquirer model.

### Refunds as a separate model

Refunds are not a status on a transaction. They are their own model with their own lifecycle. A succeeded transaction can be partially refunded multiple times up to the captured amount. `refundable_amount` is derived as `captured_amount - sum(succeeded refunds)`.

### Idempotency keys

Payment creation requires an `idempotency_key`. Retrying with the same key returns the existing payment rather than creating a duplicate. Without this, a network timeout causing the client to retry could result in a double charge.

### Cursor pagination

List endpoints use keyset pagination rather than offset. Offset pagination is `O(offset)` in PostgreSQL and produces inconsistent results when rows are inserted between pages. The cursor is the `uid` of the last record returned. The next query uses a row value comparison `WHERE (created_at, id) < (?, ?)`, which is `O(log n)` via the index and always stable.

### Cross-merchant security

All queries are scoped through `current_merchant` at the service layer. A merchant requesting another merchant's resource gets a 404 rather than 403 to avoid confirming the resource exists. This is enforced in every service, not just at the controller level.

### API key authentication via middleware

Authentication runs in `Middleware::ApiKeyAuthenticator` before the request reaches Rails. The raw API key is hashed with SHA256 on every request and compared against `api_key_digest` in the database. The plaintext key is never stored.

### Service objects and audit logging

Business logic lives in `app/services/`, not in controllers or models. Each service inherits `ApplicationService`, which wraps `perform` with structured JSON audit logging. Controllers call a service and render the result. Read-only services (`FindService`, `ListService`) skip `ApplicationService` since reads have no side effects worth logging.

### Database-level locking

Operations that involve a read-then-write (capture, refund creation) acquire a pessimistic lock with `with_lock` before reading. This prevents two concurrent requests from both reading the same state, both passing validation, and both writing, which would result in double charges or over-refunds.

### Rate limiting

Three tiers via Rack::Attack:

- Per IP: 300 requests per 5 minutes
- Per API key: 100 requests per minute
- Payment creation per merchant: 20 requests per minute
