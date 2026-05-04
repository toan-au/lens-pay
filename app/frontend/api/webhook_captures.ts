import { api } from './client'
import type { WebhookCapture } from './types'

export function listWebhookCaptures(): Promise<{ webhook_captures: WebhookCapture[] }> {
  return api.get<{ webhook_captures: WebhookCapture[] }>('/webhook-captures')
}
