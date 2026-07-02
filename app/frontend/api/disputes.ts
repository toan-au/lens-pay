import { api } from './client'
import type { Dispute, DisputeListResponse, DisputeResponse } from './types'

export function listDisputes(params?: {
  cursor?: string
  status?: string
  limit?: number
}): Promise<DisputeListResponse> {
  const query = new URLSearchParams()
  if (params?.cursor) query.set('cursor', params.cursor)
  if (params?.status) query.set('status', params.status)
  if (params?.limit) query.set('limit', String(params.limit))
  const qs = query.toString()
  return api.get<DisputeListResponse>(`/disputes${qs ? `?${qs}` : ''}`)
}

export function getDispute(uid: string): Promise<Dispute> {
  return api.get<Dispute>(`/disputes/${uid}`)
}

export function respondToDispute(uid: string, evidence: Record<string, string>): Promise<DisputeResponse> {
  return api.patch<DisputeResponse>(`/disputes/${uid}/respond`, { evidence })
}
