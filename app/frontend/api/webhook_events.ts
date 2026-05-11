import { api } from './client'
import type { WebhookEvent } from './types'

export function listWebhookEvents(): Promise<{ webhook_events: WebhookEvent[] }> {
  return api.get<{ webhook_events: WebhookEvent[] }>('/webhooks')
}
