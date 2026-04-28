# LensPay

A Stripe-like payment processing API built with Ruby on Rails. LensPay models the core of a payment gateway: merchant onboarding, the full payment lifecycle, partial captures, refunds, and outbound webhook delivery — with a focus on correctness, security, and the design decisions that real payment systems require.

Live API docs: `http://localhost:3000/api-docs`

---

## Stack

- **Ruby 4.0 / Rails 8.1**
- **PostgreSQL** (primary datastore)
- **Solid Queue** (database-backed background jobs, no Redis required)
- **AASM** (state machine for payment lifecycle)
- **rswag** (OpenAPI documentation generated from RSpec integration specs)
- **RSpec + FactoryBot** (request, service, and integration test coverage)

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

API documentation is available at `http://localhost:3000/api-docs`. Create a merchant first to get an API key, then use the Authorize button in the Swagger UI to authenticate subsequent requests.

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

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/merchants` | Register a merchant — returns API key and webhook secret (shown once) |
| `GET` | `/api/v1/merchants/me` | Fetch your merchant profile |
| `PATCH` | `/api/v1/merchants/me` | Update your merchant profile (webhook URL etc.) |
| `POST` | `/api/v1/payments` | Create a payment |
| `GET` | `/api/v1/payments` | List payments (cursor pagination, status filter) |
| `GET` | `/api/v1/payments/:uid` | Fetch a payment |
| `POST` | `/api/v1/payments/:uid/capture` | Capture an authorized payment (supports partial capture) |
| `POST` | `/api/v1/payments/:payment_uid/refunds` | Create a refund |
| `GET` | `/api/v1/payments/:payment_uid/refunds` | List refunds for a payment |
| `GET` | `/api/v1/refunds` | List all refunds across all payments |

All endpoints except `POST /merchants` require `Authorization: Bearer <api_key>`.

---

## Payment Lifecycle

```
pending → authorized → processing → succeeded
pending/authorized/processing → declined
```

Merchants create a payment (`POST /payments`) — from there, the lifecycle is driven by the payment processor, not the merchant. LensPay simulates this with background jobs:

- **`AuthorizePaymentJob`** — simulates card network authorization. On success: `pending → authorized`. On failure: `pending → declined`.
- **`SettlePaymentJob`** — simulates settlement after capture. On success: `processing → succeeded`. On failure: `processing → declined`.
- **`SettleRefundJob`** — simulates refund processing. On success: `refund → succeeded`. On failure: `refund → declined`.

**Capture** (`POST /payments/:uid/capture`) is the one merchant-facing transition — merchants decide when to move money (e.g. at shipment, not at checkout). Everything else is processor-driven.

In a real gateway, these jobs would be replaced by inbound webhooks from the card network.

---

## Webhook Delivery

LensPay fires outbound webhooks to `merchant.webhook_url` whenever a payment or refund changes state asynchronously.

Every request is signed with HMAC-SHA256 using the merchant's `webhook_secret`:

```
X-LensPay-Signature: sha256=<hex>
```

Merchants verify with a constant-time comparison against their stored secret. The secret is returned once at registration.

**Events fired:** `payment.authorized`, `payment.succeeded`, `payment.declined`, `refund.succeeded`, `refund.declined`

Delivery is handled by `WebhookDeliveryJob` on a dedicated `:webhooks` queue (isolated from `:payments` so a slow merchant endpoint cannot back up payment processing). Failed deliveries retry with exponential backoff — after 3 attempts the failure is written to the audit log and the job is discarded.

---

## Design Decisions

### Payment lifecycle as a state machine

AASM enforces valid transitions at the model level — invalid transitions raise rather than silently fail. Capture is exposed as a merchant-facing endpoint because merchants genuinely control when funds move (at shipment, not at checkout). Authorization, settlement, and decline are not merchant-facing because in a real system those are processor responses, not merchant requests.

### Partial capture

Each payment has a `captured_amount` column separate from `amount`. A merchant can capture less than the authorized amount (e.g. authorize ¥10,000, capture ¥8,000 if one item is out of stock). This matches how acquirers actually work: authorization reserves funds, capture moves them. Only one capture per transaction is supported, which is the standard model.

### Refunds as a separate model

Refunds are not a status on a transaction — they are their own model with their own lifecycle. A succeeded transaction can be partially refunded multiple times up to the captured amount. `transaction.refundable_amount` is derived as `captured_amount - refunds.succeeded.sum(:amount)`.

### Idempotency keys

Payment creation requires an `idempotency_key`. If a request is retried with the same key, the existing payment is returned rather than creating a duplicate. Without idempotency keys, a network failure causing the client to retry could charge a customer twice for the same order.

### Cursor-based pagination

List endpoints use keyset pagination rather than offset. Offset pagination is `O(offset)` in PostgreSQL and produces inconsistent results when rows are inserted between pages. The cursor is the `uid` of the last record returned — the next query uses a row value comparison `WHERE (created_at, id) < (?, ?)`, which is `O(log n)` via the index and always consistent.

### Cross-merchant security

All queries are scoped through `current_merchant` at the service layer — `Payments::FindService.call(merchant, uid)` calls `merchant.transactions.find_by(uid:)`. A merchant requesting another merchant's resource gets a 404 rather than 403 to avoid leaking that the resource exists. This is enforced in every service, not just at the controller level.

### API key authentication via middleware

Authentication is handled in `Middleware::ApiKeyAuthenticator` before the request reaches Rails. The raw API key is hashed with SHA256 and compared against `api_key_digest` stored in the database. The plaintext key is never stored — it is returned once at merchant registration.

### Service object pattern

Business logic lives in service objects under `app/services/`, not in controllers or models. Each service inherits `ApplicationService`, which wraps `perform` with structured JSON audit logging via `AuditLogger`. Controllers are thin: call a service, render the result. Read-only services (`FindService`, `ListService`) do not inherit `ApplicationService` as they have no side effects worth logging.

### Database-level locking

State transitions that involve a read-then-write (capture, refund creation) acquire a pessimistic lock with `with_lock` before reading. This prevents race conditions where two concurrent requests both read the same state, both pass validation, and both write — resulting in double-charges or over-refunds.

### Rate limiting

Three-tier rate limiting via Rack::Attack:
- **Per IP** — 300 requests/5 minutes
- **Per API key** — 100 requests/minute
- **Payment creation per merchant** — 20 requests/minute

---

## Planned

- **Row-level security** — PostgreSQL RLS as a second layer of cross-merchant isolation beneath the application layer
- **Frontend** — Vue interface to demonstrate the full payment lifecycle end to end
