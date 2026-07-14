import { api } from './client'
import type { WebhookEvent, WebhookEventListResponse } from './types'

export function listWebhookEvents(params?: {
  cursor?: number
  limit?: number
}): Promise<WebhookEventListResponse> {
  const query = new URLSearchParams()
  if (params?.cursor) query.set('cursor', String(params.cursor))
  if (params?.limit) query.set('limit', String(params.limit))
  const qs = query.toString()
  return api.get<WebhookEventListResponse>(`/webhooks${qs ? `?${qs}` : ''}`)
}

export function listPaymentWebhookEvents(paymentUid: string): Promise<{ webhook_events: WebhookEvent[] }> {
  return api.get<{ webhook_events: WebhookEvent[] }>(`/payments/${paymentUid}/webhook-events`)
}
