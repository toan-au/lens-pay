import { defineStore } from 'pinia'
import { ref } from 'vue'
import { listPayments, getPayment, createPayment, capturePayment, createRefund, listRefunds } from '../api/payments'
import type { Payment, Refund } from '../api/types'

export const usePaymentStore = defineStore('payments', () => {
  const payments = ref<Payment[]>([])
  const currentPayment = ref<Payment | null>(null)
  const currentRefunds = ref<Refund[]>([])
  const nextCursor = ref<string | null>(null)

  async function fetchPayments(params?: { cursor?: string; status?: string }): Promise<void> {
    const result = await listPayments(params)
    payments.value = params?.cursor
      ? [...payments.value, ...result.payments]
      : result.payments
    nextCursor.value = result.next_cursor
  }

  async function fetchPayment(uid: string): Promise<void> {
    currentPayment.value = await getPayment(uid)
  }

  async function submitPayment(params: {
    amount: number
    currency: string
    idempotency_key: string
  }): Promise<Payment> {
    const payment = await createPayment(params)
    payments.value = [payment, ...payments.value]
    return payment
  }

  async function capture(uid: string, capturedAmount?: number): Promise<void> {
    currentPayment.value = await capturePayment(uid, capturedAmount)
  }

  async function fetchRefunds(paymentUid: string): Promise<void> {
    const result = await listRefunds(paymentUid)
    currentRefunds.value = result.refunds
  }

  async function submitRefund(paymentUid: string, params: {
    amount: number
    idempotency_key: string
  }): Promise<void> {
    const refund = await createRefund(paymentUid, params)
    currentRefunds.value = [refund, ...currentRefunds.value]
  }

  return {
    payments,
    currentPayment,
    currentRefunds,
    nextCursor,
    fetchPayments,
    fetchPayment,
    submitPayment,
    capture,
    fetchRefunds,
    submitRefund,
  }
})
