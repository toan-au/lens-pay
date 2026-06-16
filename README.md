# LensPay

A payment gateway API built with Ruby on Rails. Covers merchant onboarding, customer management, the full payment lifecycle, partial captures, refunds, disputes, cancellations, payment expiry, and outbound webhook delivery — alongside a Vue 3 dashboard for exploring the system in real time.

Live demo: [lenspay.toanau.com](https://lenspay.toanau.com)  
API docs: [lenspay.toanau.com/api-docs](https://lenspay.toanau.com/api-docs)

---

## Demo

Click **Try the demo** on the landing page. A fresh merchant account is created with pre-seeded customers, payments in every state (pending, authorized, succeeded, declined, cancelled), refunds, disputes across all stages (open, responded, won, lost), and webhook events. No signup required.

Demo accounts are ephemeral — they expire after 24 hours and are cleaned up by a nightly scheduled job.

---

## Stack

- **Ruby 4.0 / Rails 8.1**
- **PostgreSQL**
- **Solid Queue** (database-backed background jobs, no Redis)
- **AASM** (state machine for payment lifecycle)
- **rswag** (OpenAPI docs generated from RSpec integration specs)
- **Vue 3 + Pinia** (frontend dashboard)
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
bin/dev
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

All endpoints except the ones marked public require `Authorization: Bearer <api_key>`.

Network-only endpoints (`POST /webhooks/network/...`) require an `X-Network-Secret` header matching the `NETWORK_SECRET` environment variable instead of an API key. These are not part of the merchant-facing API.

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/merchants` | Register a merchant. Returns API key and webhook secret (shown once). **Public** |
| `GET` | `/api/v1/merchants/me` | Fetch merchant profile |
| `PATCH` | `/api/v1/merchants/me` | Update merchant profile |
| `POST` | `/api/v1/demo/sessions` | Create an ephemeral demo merchant pre-seeded with data. Returns API key. **Public** |
| `POST` | `/api/v1/customers` | Create a customer |
| `GET` | `/api/v1/customers` | List customers (cursor pagination) |
| `GET` | `/api/v1/customers/:uid` | Fetch a customer |
| `PATCH` | `/api/v1/customers/:uid` | Update a customer |
| `DELETE` | `/api/v1/customers/:uid` | Soft-delete a customer |
| `POST` | `/api/v1/payments` | Create a payment (optional `customer_uid`) |
| `GET` | `/api/v1/payments` | List payments (cursor pagination, status filter) |
| `GET` | `/api/v1/payments/:uid` | Fetch a payment |
| `POST` | `/api/v1/payments/:uid/capture` | Capture an authorized payment (supports partial capture) |
| `POST` | `/api/v1/payments/:uid/cancel` | Cancel a pending or authorized payment |
| `POST` | `/api/v1/payments/:payment_uid/refunds` | Create a refund |
| `GET` | `/api/v1/payments/:payment_uid/refunds` | List refunds for a payment |
| `GET` | `/api/v1/payments/:uid/webhook-events` | List webhook events for a specific payment |
| `GET` | `/api/v1/refunds` | List all refunds |
| `GET` | `/api/v1/disputes` | List disputes (cursor pagination, status filter) |
| `GET` | `/api/v1/disputes/:uid` | Fetch a dispute |
| `PATCH` | `/api/v1/disputes/:uid/respond` | Submit evidence for a dispute |
| `GET` | `/api/v1/webhooks` | List all received webhook events |
| `POST` | `/api/v1/webhooks/ping` | Fire a test ping webhook |
| `POST` | `/api/v1/webhooks/:merchant_uid` | Receive and store a signed webhook event (public sink). **Public** |
| `POST` | `/api/v1/webhooks/network/disputes` | Card network opens a dispute (`X-Network-Secret` auth). **Network only** |
| `POST` | `/api/v1/webhooks/network/disputes/:uid/resolve` | Card network resolves a dispute as won or lost. **Network only** |

---

## Payment Lifecycle

```
pending → authorized → processing → succeeded
pending / authorized → cancelled
pending / authorized / processing → declined
pending → expired (via scheduled job)
```

Merchants create a payment via `POST /payments`. The lifecycle from there is mostly processor-driven. LensPay simulates the processor with background jobs:

- **`AuthorizePaymentJob`** — simulates card network authorization. `pending → authorized` or `pending → declined`.
- **`SettlePaymentJob`** — simulates settlement after capture. `processing → succeeded` or `processing → declined`.
- **`SettleRefundJob`** — simulates refund processing. `pending → succeeded` or `pending → declined`.
- **`ExpirePaymentsJob`** — runs on a schedule every 5 minutes (production). Finds pending payments past their `expires_at` and transitions them to `expired`. Models payment methods like konbini where a customer has a fixed window to pay.
- **`CleanupDemoMerchantsJob`** — runs nightly. Destroys demo merchant accounts whose 24-hour window has passed, cascading to all associated data.

Merchant-facing transitions: `capture` and `cancel`. Everything else is processor-driven.

Each payment gets an `expires_at` of 3 days from creation. This can be extended in future to support per-payment-method windows.

---

## Dispute Lifecycle

```
open → merchant_responded → won
open → merchant_responded → lost
open → won
open → lost
```

Disputes are opened by the card network against succeeded payments. The merchant has 7 days to submit evidence via `PATCH /disputes/:uid/respond`. The network then resolves the dispute as `won` (merchant keeps the funds) or `lost` (funds returned to the cardholder).

Merchants can submit evidence multiple times before the deadline — each submission creates a new `DisputeResponse` record. Once resolved, the dispute cannot be reopened.

---

## Webhook Delivery

After each state transition, LensPay posts a signed JSON event to the merchant's `webhook_url`.

Every request includes an HMAC-SHA256 signature:

```
X-LensPay-Signature: sha256=<hex>
```

The signature is computed over the raw request body using the merchant's `webhook_secret`. Verify it server-side with a constant-time comparison against your own recomputed signature.

**Events fired:**

| Event | When |
|-------|------|
| `payment.authorized` | Payment authorized by processor |
| `payment.captured` | Merchant captures an authorized payment |
| `payment.succeeded` | Captured payment fully settles |
| `payment.failed` | Payment declined at any stage |
| `payment.cancelled` | Merchant cancels a pending or authorized payment |
| `payment.expired` | Pending payment passes its expiry window |
| `payment.refund.created` | Merchant initiates a refund |
| `payment.refunded` | Refund settles successfully |
| `payment.refund.failed` | Refund fails to settle |
| `dispute.opened` | Card network opens a dispute on a payment |
| `dispute.responded` | Merchant submits evidence |
| `dispute.won` | Card network rules in the merchant's favour |
| `dispute.lost` | Card network rules in the cardholder's favour |
| `ping` | Merchant tests their webhook endpoint |

Delivery runs in `WebhookDeliveryJob` on an isolated `:webhooks` queue so a slow merchant endpoint cannot back up payment processing. Failed deliveries retry with exponential backoff (30s, then 5 minutes). After 3 attempts the failure is written to the audit log.

Each merchant's `webhook_url` is automatically set to `/api/v1/webhooks/:merchant_uid` on registration. This endpoint verifies the HMAC signature and stores the event. The frontend displays received events on the Payment Detail page and the Webhooks index, so the full delivery loop is visible without an external server.

---

## Design Decisions

### Payment lifecycle as a state machine

AASM enforces valid transitions at the model level. Invalid transitions raise rather than silently fail. Each transition has a dedicated service object (`AuthorizeService`, `CaptureService`, `CancelService`, `ExpireService`, etc.) rather than putting logic in callbacks or the model itself.

### Partial capture

Each payment has a `captured_amount` column separate from `amount`. A merchant can capture less than the authorized amount (e.g. authorize ¥10,000, capture ¥8,000 if one item is out of stock). Only one capture per transaction is supported, which matches the standard acquirer model.

### Refunds as a separate model

Refunds are not a status on a transaction — they are their own model with their own lifecycle. A succeeded transaction can be partially refunded multiple times up to the captured amount. `refundable_amount` is derived as `captured_amount - sum(pending + succeeded refunds)`.

### Customer model and payment snapshots

Customers are a first-class resource scoped to a merchant. They can be attached to a payment via `customer_uid` at creation time. When a customer is attached, their name and email are snapshotted onto the transaction at the moment of payment — stored as `customer_name` and `customer_email` columns on the `transactions` table.

This means the payment record is immutable with respect to the customer: if the customer later changes their email or is deleted, the payment still reflects who was charged and at what contact details. The `customer_id` foreign key is preserved for relational queries (`customer.payments`), while the snapshot columns serve the response payload.

Customers support soft deletion via a `deleted_at` column. Deleted customers are excluded from list endpoints and cannot be attached to new payments, but their historical payment records and the snapshot data remain intact.

### Idempotency keys

Payment creation requires an `idempotency_key`. Retrying with the same key returns the existing payment rather than creating a duplicate, preventing double charges on network timeouts. Refund creation uses the same pattern.

### Pessimistic locking on all state transitions

Every service that transitions state wraps the transition in `with_lock` (`SELECT ... FOR UPDATE`). This prevents two concurrent requests from both reading the same state, both passing AASM validation, and both writing — which would otherwise allow a payment to be simultaneously captured and cancelled, or a refund to exceed the refundable amount.

The lock is kept narrow: only the database write happens inside `with_lock`. Side effects (webhook jobs, audit logs) run after the lock is released, so a slow webhook queue never holds a row lock.

### Cursor pagination

List endpoints use keyset pagination rather than offset. Offset pagination is `O(offset)` in PostgreSQL and produces inconsistent results when rows are inserted between pages. The cursor is the `uid` of the last record returned. The next query uses `WHERE (created_at, id) < (?, ?)`, which is `O(log n)` via the index and always stable.

### Cross-merchant security

All queries are scoped through `current_merchant` at the service layer. A merchant requesting another merchant's resource gets a 404 rather than 403 to avoid confirming the resource exists.

### API key authentication via middleware

Authentication runs in `Middleware::ApiKeyAuthenticator` before the request reaches Rails routing. The raw API key is hashed with SHA256 on every request and compared against `api_key_digest` in the database. The plaintext key is never stored.

### Service objects and audit logging

Business logic lives in `app/services/`, not in controllers or models. Each service inherits `ApplicationService`, which wraps `perform` with structured JSON audit logging. Controllers call a service and render the result.

### Disputes

Disputes are opened by the card network, not by merchants. This reflects how chargebacks actually work — a cardholder contacts their bank, the bank notifies the processor, and the processor notifies the merchant. The merchant's role is to respond with evidence; the network decides the outcome.

This is modelled with two separate endpoints: one for the network to open a dispute (`POST /webhooks/network/disputes`) and one for the network to send the outcome (`POST /webhooks/network/disputes/:uid/resolve`). Both are protected by a shared `NETWORK_SECRET` rather than merchant API keys. Merchants can read and respond to their disputes but cannot create or resolve them.

The dispute lifecycle (`open → merchant_responded → won/lost`) runs through AASM with the same pessimistic locking as payment transitions. Each transition fires a signed webhook to the merchant.

### Rate limiting

Three tiers via Rack::Attack:

- Per IP: 300 requests per 5 minutes
- Per API key: 300 requests per 5 minutes
- Merchant registration: 10 per hour per IP
