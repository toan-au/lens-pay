import { defineStore } from 'pinia'
import { ref } from 'vue'
import { listDisputes, getDispute, respondToDispute } from '../api/disputes'
import type { Dispute, DisputeResponse } from '../api/types'

export const useDisputeStore = defineStore('disputes', () => {
  const disputes = ref<Dispute[]>([])
  const currentDispute = ref<Dispute | null>(null)
  const currentResponses = ref<DisputeResponse[]>([])
  const nextCursor = ref<string | null>(null)

  async function fetchDisputes(params?: { cursor?: string; status?: string }): Promise<void> {
    const result = await listDisputes(params)
    disputes.value = params?.cursor
      ? [...disputes.value, ...result.disputes]
      : result.disputes
    nextCursor.value = result.next_cursor
  }

  async function fetchDispute(uid: string): Promise<void> {
    currentDispute.value = await getDispute(uid)
  }

  async function submitResponse(uid: string, evidence: Record<string, string>): Promise<DisputeResponse> {
    const response = await respondToDispute(uid, evidence)
    currentResponses.value = [response, ...currentResponses.value]
    await fetchDispute(uid)
    return response
  }

  return {
    disputes,
    currentDispute,
    currentResponses,
    nextCursor,
    fetchDisputes,
    fetchDispute,
    submitResponse,
  }
})
