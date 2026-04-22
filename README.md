# LensPay

A Stripe-like payment processing API built with Ruby on Rails. LensPay models the core of a payment gateway: merchant onboarding, the full payment lifecycle, partial captures, and refunds, with a focus on correctness, security, and the design decisions that real payment systems require.

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
| POST | `/api/v1/merchants` | Create a merchant, returns API key (shown once) |
| GET | `/api/v1/merchants/:uid` | Fetch your merchant profile |
| POST | `/api/v1/payments` | Create a payment |
| GET | `/api/v1/payments` | List payments (cursor pagination, status filter) |
| GET | `/api/v1/payments/:uid` | Fetch a payment |
| POST | `/api/v1/payments/:uid/authorize` | Authorize a pending payment |
| POST | `/api/v1/payments/:uid/capture` | Capture an authorized payment (supports partial capture) |
| POST | `/api/v1/payments/:uid/complete` | Mark a captured payment as succeeded |
| POST | `/api/v1/payments/:uid/decline` | Decline a payment |
| POST | `/api/v1/payments/:uid/refunds` | Create a refund |
| GET | `/api/v1/payments/:uid/refunds` | List refunds for a payment |
| GET | `/api/v1/refunds` | List all refunds across all payments |

All endpoints except `POST /merchants` require `Authorization: Bearer <api_key>`.

---

## Design Decisions

### Payment lifecycle as a state machine

Payments follow a strict lifecycle: `pending -> authorized -> processing -> succeeded`, with `declined` reachable from any non-terminal state. AASM enforces valid transitions at the model level, invalid transitions raise rather than silently fail. The transition endpoints (`/authorize`, `/capture`, `/complete`, `/decline`) are exposed manually rather than via a generic `PATCH /payments/:uid` to make the intent of each operation explicit in the API contract.

In a real gateway, most transitions would be triggered internally by responses from a card network. Capture is the exception, it is genuinely merchant-facing because merchants decide when to move money (e.g. at shipment). The other transitions are exposed here to make the state machine demonstrable without a real card network.

### Partial capture

Each payment has a `captured_amount` column separate from `amount`. A merchant can capture less than the authorized amount (e.g. authorize 10,000 JPY, capture 8,000 JPY if one item is out of stock). This matches how acquirers actually work: authorization reserves funds, capture moves them. Only one capture per transaction is supported, which is the standard model.

### Refunds as a separate model

Refunds are not a status on a transaction, they are their own model with their own lifecycle. A succeeded transaction can be partially refunded multiple times up to the captured amount. If `refunded` were a terminal status on the transaction, partial refund history would be lost and multiple refunds would be impossible. `transaction.refundable_amount` is derived as `captured_amount - refunds.succeeded.sum(:amount)`.

### Idempotency keys

Payment creation requires an `idempotency_key`. If a request is retried with the same key, the existing payment is returned rather than creating a duplicate. This matters in payment systems where network failures cause clients to retry: without idempotency keys, a customer could be charged multiple times for the same order.

### Cursor-based pagination

List endpoints use keyset pagination rather than offset. Offset pagination is `O(offset)` in PostgreSQL and produces inconsistent results when rows are inserted between pages. The cursor is the `uid` of the last record returned. The next query looks up that record to get its `(created_at, id)` and uses a row value comparison `WHERE (created_at, id) < (?, ?)`. This is `O(log n)` via the index and always consistent.

### Cross-merchant security

All queries are scoped through `current_merchant` at the service layer. `Payments::FindService.call(merchant, uid)` calls `merchant.transactions.find_by(uid:)`. A merchant requesting another merchant's payment gets a 404 rather than a 403 to avoid leaking that the resource exists. This is enforced in every service, not just controllers.

### API key authentication via middleware

Authentication is handled in `Middleware::ApiKeyAuthenticator` before the request reaches Rails. The raw API key is hashed with SHA256 and compared against `api_key_digest` stored in the database. The plaintext key is returned once at merchant creation and never stored.

### Service object pattern

Business logic lives in service objects under `app/services/`, not in controllers or models. Each service inherits `ApplicationService`, which wraps `perform` with structured JSON audit logging via `AuditLogger`. Controllers are thin: call a service, render the result. Read-only services (`FindService`, `ListService`) do not inherit `ApplicationService` as they have no side effects worth logging.

---

## Planned

- **Webhook delivery**: HMAC-signed `POST` to `merchant.webhook_url` on payment and refund events, with a `WebhookDelivery` audit record and retry logic on failure
- **Row-level security**: PostgreSQL RLS as a second layer of cross-merchant isolation beneath the application layer (currently researching implementation)
- **Frontend**: Vue interface to demonstrate the full payment lifecycle end to end
