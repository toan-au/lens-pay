export interface Merchant {
  uid: string
  name: string
  email: string
  country: string
  currency: string
  status: string
  webhook_url: string | null
  webhook_secret: string
}

export interface MerchantCreateResponse {
  uid: string
  api_key: string
  webhook_secret: string
}

export interface PaymentCustomer {
  uid: string | null
  name: string
  email: string
}

export interface Payment {
  uid: string
  amount: number
  currency: string
  status: 'pending' | 'authorized' | 'processing' | 'succeeded' | 'declined' | 'cancelled' | 'expired'
  captured_amount: number | null
  idempotency_key: string
  merchant_uid: string
  metadata: Record<string, string>
  customer: PaymentCustomer | null
  dispute_status: 'open' | 'merchant_responded' | 'won' | 'lost' | null
  dispute: Pick<Dispute, 'uid' | 'status' | 'reason' | 'amount' | 'currency' | 'respond_by' | 'resolved_at'> | null
  created_at: string
  expires_at: string | null
}

export interface PaymentListResponse {
  payments: Payment[]
  next_cursor: string | null
}

export interface Refund {
  uid: string
  amount: number
  status: 'pending' | 'succeeded' | 'failed'
  created_at: string
  payment_uid?: string
  currency?: string
}

export interface RefundListResponse {
  refunds: Refund[]
  next_cursor: string | null
}

export interface Customer {
  uid: string
  name: string
  email: string
  metadata: Record<string, string> | null
  deleted_at: string | null
  created_at: string
}

export interface CustomerListResponse {
  customers: Customer[]
  next_cursor: string | null
}

export interface WebhookEvent {
  id: number
  event_type: string
  payload: Record<string, any>
  created_at: string
}

export interface DisputeResponse {
  id: number
  evidence: Record<string, string>
  created_at: string
}

export interface Dispute {
  uid: string
  status: 'open' | 'merchant_responded' | 'won' | 'lost'
  reason: string
  amount: number
  currency: string
  respond_by: string
  resolved_at: string | null
  created_at: string
  dispute_responses: DisputeResponse[]
}

export interface DisputeListResponse {
  disputes: Dispute[]
  next_cursor: string | null
}
