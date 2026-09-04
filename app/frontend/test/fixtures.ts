import type {
  Customer,
  Dispute,
  DisputeResponse,
  Merchant,
  MerchantCreateResponse,
  Payment,
  Refund,
  WebhookEvent,
} from "../api/types";

export function buildMerchant(overrides: Partial<Merchant> = {}): Merchant {
  return {
    uid: "mch_1",
    name: "Acme",
    email: "owner@acme.test",
    country: "JP",
    currency: "JPY",
    status: "active",
    webhook_url: null,
    webhook_secret: "whs_test_1",
    ...overrides,
  };
}

export function buildMerchantCreateResponse(
  overrides: Partial<MerchantCreateResponse> = {},
): MerchantCreateResponse {
  return { uid: "mch_1", api_key: "lp_test_1", webhook_secret: "whs_test_1", ...overrides };
}

export function buildPayment(overrides: Partial<Payment> = {}): Payment {
  return {
    uid: "pay_1",
    amount: 1000,
    currency: "USD",
    status: "succeeded",
    payment_method: "card",
    provider_reference: null,
    captured_amount: 1000,
    idempotency_key: "idem_1",
    merchant_uid: "mch_1",
    metadata: {},
    customer: null,
    dispute_status: null,
    dispute: null,
    created_at: "2024-01-01T00:00:00Z",
    expires_at: null,
    ...overrides,
  };
}

export function buildRefund(overrides: Partial<Refund> = {}): Refund {
  return {
    uid: "re_1",
    amount: 500,
    status: "succeeded",
    created_at: "2024-01-02T00:00:00Z",
    ...overrides,
  };
}

export function buildCustomer(overrides: Partial<Customer> = {}): Customer {
  return {
    uid: "cus_1",
    name: "Alice",
    email: "alice@example.com",
    metadata: null,
    deleted_at: null,
    created_at: "2024-01-01T00:00:00Z",
    ...overrides,
  };
}

export function buildDisputeResponse(
  overrides: Partial<DisputeResponse> = {},
): DisputeResponse {
  return {
    id: 1,
    evidence: { note: "shipped on time" },
    created_at: "2024-01-03T00:00:00Z",
    ...overrides,
  };
}

export function buildDispute(overrides: Partial<Dispute> = {}): Dispute {
  return {
    uid: "dp_1",
    status: "open",
    reason: "fraudulent",
    amount: 1000,
    currency: "USD",
    respond_by: "2024-02-01T00:00:00Z",
    resolved_at: null,
    created_at: "2024-01-01T00:00:00Z",
    dispute_responses: [],
    ...overrides,
  };
}

export function buildWebhookEvent(overrides: Partial<WebhookEvent> = {}): WebhookEvent {
  return {
    id: 1,
    event_type: "payment.succeeded",
    payload: {},
    created_at: "2024-01-01T00:00:00Z",
    ...overrides,
  };
}
