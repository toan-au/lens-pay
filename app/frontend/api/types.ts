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

export interface Payment {
  uid: string
  amount: number
  currency: string
  status: 'pending' | 'authorized' | 'processing' | 'succeeded' | 'declined'
  captured_amount: number | null
  idempotency_key: string
  merchant_uid: string
  metadata: Record<string, string>
  created_at: string
}

export interface PaymentListResponse {
  payments: Payment[]
  next_cursor: string | null
}

export interface Refund {
  uid: string
  amount: number
  status: 'pending' | 'succeeded' | 'declined'
  created_at: string
  payment_uid?: string
  currency?: string
}

export interface RefundListResponse {
  refunds: Refund[]
  next_cursor: string | null
}
