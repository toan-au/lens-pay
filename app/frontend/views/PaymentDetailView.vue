<template>
  <div class="flex flex-col gap-6 max-w-2xl">
    <button @click="router.back()" class="btn-ghost text-xs w-fit cursor-pointer">← Back</button>

    <div v-if="!payment" class="text-gray-400 text-sm">Loading...</div>

    <template v-else>
      <div class="flex items-start justify-between">
        <div class="flex flex-col gap-1">
          <h1 class="text-xl font-bold font-mono">{{ payment.uid }}</h1>
          <p class="text-xs text-gray-400">{{ formatDate(payment.created_at) }}</p>
        </div>
        <StatusBadge :status="payment.status" />
      </div>

      <DetailCard>
        <DetailRow label="Amount">
          <span class="text-sm font-medium">{{ formatAmount(payment.amount, payment.currency) }}</span>
        </DetailRow>
        <DetailRow label="Captured">
          <span class="text-sm font-medium">
            {{ payment.captured_amount != null ? formatAmount(payment.captured_amount, payment.currency) : '—' }}
          </span>
        </DetailRow>
        <DetailRow label="Currency">
          <span class="text-sm font-medium">{{ payment.currency }}</span>
        </DetailRow>
        <DetailRow label="Method">
          <span class="text-sm font-medium">{{ METHOD_LABELS[payment.payment_method] ?? payment.payment_method }}</span>
        </DetailRow>
        <DetailRow v-if="payment.provider_reference" label="Network reference">
          <span class="text-xs font-mono text-gray-600">{{ payment.provider_reference }}</span>
        </DetailRow>
        <DetailRow label="Idempotency key">
          <span class="text-xs font-mono text-gray-600">{{ payment.idempotency_key }}</span>
        </DetailRow>
        <DetailRow v-if="payment.expires_at" label="Expires">
          <span class="text-sm font-medium">{{ formatDate(payment.expires_at) }}</span>
        </DetailRow>
        <template v-if="payment.customer">
          <DetailRow label="Customer">
            <RouterLink :to="`/customers/${payment.customer.uid}`" class="text-sm text-indigo-600 hover:underline">
              {{ payment.customer.name }}
            </RouterLink>
          </DetailRow>
          <DetailRow label="Customer email">
            <span class="text-sm text-gray-600">{{ payment.customer.email }}</span>
          </DetailRow>
        </template>
        <template v-if="Object.keys(payment.metadata ?? {}).length > 0">
          <DetailRow v-for="(value, key) in payment.metadata" :key="key" :label="String(key)" label-class="font-mono">
            <span class="text-sm text-gray-700 font-mono">{{ value }}</span>
          </DetailRow>
        </template>
      </DetailCard>

      <!-- Dispute section -->
      <div v-if="payment.dispute" class="bg-white rounded-xl border border-gray-200 p-5 flex flex-col gap-3">
        <div class="flex items-center justify-between">
          <h2 class="font-semibold">Dispute</h2>
          <StatusBadge :status="payment.dispute.status" />
        </div>
        <div class="flex flex-col gap-1 text-sm">
          <div class="flex justify-between">
            <span class="text-gray-500">Reason</span>
            <span class="font-medium">{{ DISPUTE_REASON_LABELS[payment.dispute.reason] ?? payment.dispute.reason }}</span>
          </div>
          <div class="flex justify-between">
            <span class="text-gray-500">Amount</span>
            <span class="font-medium">{{ formatAmount(payment.dispute.amount, payment.dispute.currency) }}</span>
          </div>
          <div class="flex justify-between">
            <span class="text-gray-500">Respond by</span>
            <span :class="isDisputeOverdue ? 'text-red-500 font-medium' : ''">
              {{ formatDate(payment.dispute.respond_by) }}
            </span>
          </div>
        </div>
        <RouterLink :to="`/disputes/${payment.dispute.uid}`" class="text-sm text-indigo-600 hover:underline w-fit">
          View dispute →
        </RouterLink>
      </div>

      <div v-if="isPolling" class="flex items-center gap-2 text-sm text-amber-600">
        <span class="animate-pulse">●</span> {{ pollingMessage }}
      </div>

      <div v-if="isAwaitingCustomerPayment" class="bg-white rounded-xl border border-gray-200 p-5 flex flex-col gap-3">
        <h2 class="font-semibold">Awaiting customer payment</h2>
        <p class="text-sm text-gray-500">
          {{ payment.payment_method === 'konbini'
            ? 'The customer has until the expiry date to pay at a convenience store.'
            : 'The customer has until the expiry date to complete the bank transfer.' }}
          In a real integration the network notifies LensPay when payment arrives — use the button to simulate that.
        </p>
        <p v-if="simulateError" class="text-sm text-red-500">{{ simulateError }}</p>
        <button @click="handleSimulate" :disabled="simulating" class="btn-primary w-fit">
          {{ simulating ? 'Confirming...' : 'Simulate customer paying' }}
        </button>
      </div>

      <CaptureForm
        v-if="payment.status === 'authorized'"
        :amount="payment.amount"
        :currency="payment.currency"
        :on-capture="handleCapture"
      />

      <div v-if="payment.status === 'pending' || payment.status === 'authorized'" class="bg-white rounded-xl border border-gray-200 p-5 flex flex-col gap-3">
        <h2 class="font-semibold">Cancel Payment</h2>
        <p class="text-sm text-gray-500">Void this payment and release any reserved funds. This cannot be undone.</p>
        <p v-if="cancelError" class="text-sm text-red-500">{{ cancelError }}</p>
        <button @click="handleCancel" :disabled="cancelling" class="btn-danger w-fit">
          {{ cancelling ? 'Cancelling...' : 'Cancel Payment' }}
        </button>
      </div>

      <RefundsSection
        v-if="payment.status === 'succeeded'"
        :captured-amount="payment.captured_amount!"
        :currency="payment.currency"
        :refunds="paymentStore.currentRefunds"
        :on-refund="handleRefund"
      />

      <WebhookEventsPanel :uid="uid" :status="payment.status" />
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { usePaymentStore } from '../stores/payments'
import { formatAmount, formatDate } from '../utils/format'
import { useAsyncAction } from '../composables/useAsyncAction'
import { usePolling } from '../composables/usePolling'
import StatusBadge from '../components/ui/StatusBadge.vue'
import DetailCard from '../components/ui/DetailCard.vue'
import DetailRow from '../components/ui/DetailRow.vue'
import CaptureForm from '../components/features/CaptureForm.vue'
import RefundsSection from '../components/features/RefundsSection.vue'
import WebhookEventsPanel from '../components/features/WebhookEventsPanel.vue'

const POLL_STATUSES = ['pending', 'processing']

const METHOD_LABELS: Record<string, string> = {
  card: 'Card',
  konbini: 'Konbini',
  bank_transfer: 'Bank Transfer',
}

const DISPUTE_REASON_LABELS: Record<string, string> = {
  fraudulent: 'Fraudulent',
  unrecognized: 'Unrecognized',
  duplicate: 'Duplicate',
  product_not_received: 'Product not received',
  product_unacceptable: 'Product unacceptable',
}

const route = useRoute()
const router = useRouter()
const paymentStore = usePaymentStore()
const uid = route.params.uid as string
const payment = computed(() => paymentStore.currentPayment)
const isDisputeOverdue = computed(() =>
  payment.value?.dispute ? new Date(payment.value.dispute.respond_by) < new Date() : false
)

const { loading: cancelling, error: cancelError, run: runCancel } = useAsyncAction()
const { loading: simulating, error: simulateError, run: runSimulate } = useAsyncAction()

const isCashMethod = computed(() =>
  payment.value?.payment_method === 'konbini' || payment.value?.payment_method === 'bank_transfer'
)
const isAwaitingCustomerPayment = computed(() =>
  isCashMethod.value && payment.value?.status === 'pending'
)

const pollingMessage = computed(() => {
  if (payment.value?.status === 'pending') return 'Simulating card network authorization...'
  if (payment.value?.status === 'processing') return 'Simulating network settlement...'
  if (paymentStore.currentRefunds.some(r => r.status === 'pending')) return 'Processing refund...'
  return 'Waiting...'
})

function needsPolling() {
  // Pending cash payments wait for the customer, not a background job.
  if (isAwaitingCustomerPayment.value) return paymentStore.currentRefunds.some(r => r.status === 'pending')
  return POLL_STATUSES.includes(payment.value?.status ?? '') ||
    paymentStore.currentRefunds.some(r => r.status === 'pending')
}

const { active: isPolling, start: startPolling, stop: stopPolling } = usePolling(async () => {
  if (POLL_STATUSES.includes(payment.value?.status ?? '')) await paymentStore.fetchPayment(uid)
  if (payment.value?.status === 'succeeded') await paymentStore.fetchRefunds(uid)
  return needsPolling()
})

async function handleCapture(amount?: number) {
  await paymentStore.capture(uid, amount)
  if (needsPolling()) startPolling()
}

async function handleSimulate() {
  await runSimulate(async () => {
    await paymentStore.simulateCashPayment(uid)
    if (needsPolling()) startPolling()
  })
}

async function handleCancel() {
  await runCancel(async () => {
    await paymentStore.cancel(uid)
    stopPolling()
  })
}

async function handleRefund(amount: number) {
  await paymentStore.submitRefund(uid, { amount, idempotency_key: crypto.randomUUID() })
  if (needsPolling()) startPolling()
}

onMounted(async () => {
  await paymentStore.fetchPayment(uid)
  await paymentStore.fetchRefunds(uid)
  if (needsPolling()) startPolling()
})

onUnmounted(() => {
  stopPolling()
  paymentStore.currentPayment = null
  paymentStore.currentRefunds = []
})
</script>
