import { api } from './client'
import type { Payment, PaymentListResponse, Refund } from './types'

export function createPayment(params: {
  amount: number
  currency: string
  idempotency_key: string
}): Promise<Payment> {
  return api.post<Payment>('/payments', params)
}

export function getPayment(uid: string): Promise<Payment> {
  return api.get<Payment>(`/payments/${uid}`)
}

export function listPayments(params?: {
  cursor?: string
  status?: string
  limit?: number
}): Promise<PaymentListResponse> {
  const query = new URLSearchParams()
  if (params?.cursor) query.set('cursor', params.cursor)
  if (params?.status) query.set('status', params.status)
  if (params?.limit) query.set('limit', String(params.limit))
  const qs = query.toString()
  return api.get<PaymentListResponse>(`/payments${qs ? `?${qs}` : ''}`)
}

export function capturePayment(uid: string, capturedAmount?: number): Promise<Payment> {
  return api.post<Payment>(`/payments/${uid}/capture`, { captured_amount: capturedAmount })
}

export function createRefund(paymentUid: string, params: {
  amount: number
  idempotency_key: string
}): Promise<Refund> {
  return api.post<Refund>(`/payments/${paymentUid}/refunds`, params)
}

export function listRefunds(paymentUid: string): Promise<{ refunds: Refund[] }> {
  return api.get<{ refunds: Refund[] }>(`/payments/${paymentUid}/refunds`)
}
