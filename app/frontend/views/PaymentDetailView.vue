<template>
  <div class="flex flex-col gap-6 max-w-2xl">
    <button @click="router.back()" class="btn-ghost text-xs w-fit cursor-pointer">← Back</button>

    <div v-if="!payment" class="text-gray-400 text-sm">Loading...</div>

    <template v-else>
      <!-- Header -->
      <div class="flex items-start justify-between">
        <div class="flex flex-col gap-1">
          <h1 class="text-xl font-bold font-mono">{{ payment.uid }}</h1>
          <p class="text-xs text-gray-400">{{ formatDate(payment.created_at) }}</p>
        </div>
        <span :class="statusClass(payment.status)">{{ payment.status }}</span>
      </div>

      <!-- Details card -->
      <div class="bg-white rounded-xl border border-gray-200 divide-y divide-gray-100">
        <div class="flex justify-between px-5 py-4">
          <span class="text-sm text-gray-500">Amount</span>
          <span class="text-sm font-medium">{{ formatAmount(payment.amount, payment.currency) }}</span>
        </div>
        <div class="flex justify-between px-5 py-4">
          <span class="text-sm text-gray-500">Captured</span>
          <span class="text-sm font-medium">
            {{ payment.captured_amount != null ? formatAmount(payment.captured_amount, payment.currency) : '—' }}
          </span>
        </div>
        <div class="flex justify-between px-5 py-4">
          <span class="text-sm text-gray-500">Currency</span>
          <span class="text-sm font-medium">{{ payment.currency }}</span>
        </div>
        <div class="flex justify-between px-5 py-4">
          <span class="text-sm text-gray-500">Idempotency key</span>
          <span class="text-xs font-mono text-gray-600">{{ payment.idempotency_key }}</span>
        </div>
        <template v-if="Object.keys(payment.metadata ?? {}).length > 0">
          <div
            v-for="(value, key) in payment.metadata"
            :key="key"
            class="flex justify-between px-5 py-4"
          >
            <span class="text-sm text-gray-500 font-mono">{{ key }}</span>
            <span class="text-sm text-gray-700 font-mono">{{ value }}</span>
          </div>
        </template>
      </div>

      <!-- Polling indicator -->
      <div v-if="isPolling" class="flex items-center gap-2 text-sm text-amber-600">
        <span class="animate-pulse">●</span> Waiting for payment to settle...
      </div>

      <!-- Capture section (only when authorized) -->
      <div v-if="payment.status === 'authorized'" class="bg-white rounded-xl border border-gray-200 p-5 flex flex-col gap-4">
        <h2 class="font-semibold">Capture Payment</h2>
        <form @submit.prevent="handleCapture" class="flex flex-col gap-3">
          <div class="flex flex-col gap-1">
            <label class="text-sm font-medium">
              Amount
              <span class="text-gray-400 font-normal">— leave blank to capture full amount</span>
            </label>
            <div class="flex gap-2">
              <input
                v-model.number="captureAmount"
                type="number"
                min="1"
                :max="payment.amount"
                :placeholder="String(payment.amount)"
                class="input flex-1"
              />
              <span class="input bg-gray-50 text-gray-500 min-w-16 text-center">{{ payment.currency }}</span>
            </div>
          </div>
          <p v-if="captureError" class="text-sm text-red-500">{{ captureError }}</p>
          <button type="submit" :disabled="capturing" class="btn-primary">
            {{ capturing ? 'Capturing...' : `Capture ${formatAmount(captureAmount || payment.amount, payment.currency)}` }}
          </button>
        </form>
      </div>

      <!-- Refunds section (only when succeeded) -->
      <div v-if="payment.status === 'succeeded'" class="flex flex-col gap-4">
        <h2 class="font-semibold">Refunds</h2>

        <div v-if="paymentStore.currentRefunds.length > 0" class="bg-white rounded-xl border border-gray-200 divide-y divide-gray-100">
          <div
            v-for="refund in paymentStore.currentRefunds"
            :key="refund.uid"
            class="flex items-center justify-between px-5 py-4"
          >
            <div class="flex flex-col gap-0.5">
              <span class="text-sm font-medium">{{ formatAmount(refund.amount, payment.currency) }}</span>
              <span class="text-xs text-gray-400">{{ formatDate(refund.created_at) }}</span>
            </div>
            <span :class="statusClass(refund.status)">{{ refund.status }}</span>
          </div>
        </div>

        <p v-else class="text-sm text-gray-400">No refunds yet.</p>

        <div v-if="remainingAmount > 0" class="bg-white rounded-xl border border-gray-200 p-5 flex flex-col gap-4">
          <h3 class="font-semibold text-sm">Issue Refund</h3>
          <form @submit.prevent="handleRefund" class="flex flex-col gap-3">
            <div class="flex flex-col gap-1">
              <label class="text-sm font-medium">
                Amount
                <span class="text-gray-400 font-normal">— max {{ formatAmount(remainingAmount, payment.currency) }}</span>
              </label>
              <div class="flex gap-2">
                <input
                  v-model.number="refundAmount"
                  type="number"
                  min="1"
                  :max="remainingAmount"
                  :placeholder="String(remainingAmount)"
                  class="input flex-1"
                />
                <span class="input bg-gray-50 text-gray-500 min-w-16 text-center">{{ payment.currency }}</span>
              </div>
            </div>
            <p v-if="refundError" class="text-sm text-red-500">{{ refundError }}</p>
            <button type="submit" :disabled="refunding" class="btn-primary">
              {{ refunding ? 'Refunding...' : 'Issue Refund' }}
            </button>
          </form>
        </div>

        <p v-else class="text-sm text-gray-500">Fully refunded.</p>
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { usePaymentStore } from '../stores/payments'
import { formatAmount, formatDate, statusClass } from '../utils/format'

const POLL_PAYMENT_STATUSES = ['pending', 'processing']

const route = useRoute()
const router = useRouter()
const paymentStore = usePaymentStore()

const uid = route.params.uid as string
const payment = computed(() => paymentStore.currentPayment)

const isPolling = ref(false)
const captureAmount = ref<number | null>(null)
const captureError = ref('')
const capturing = ref(false)
const refundAmount = ref<number | null>(null)
const refundError = ref('')
const refunding = ref(false)

const remainingAmount = computed(() => {
  if (!payment.value?.captured_amount) return 0
  const refunded = paymentStore.currentRefunds
    .filter(r => r.status === 'succeeded')
    .reduce((sum, r) => sum + r.amount, 0)
  return payment.value.captured_amount - refunded
})

let pollTimeout: ReturnType<typeof setTimeout> | null = null

function needsPolling(): boolean {
  const paymentPending = POLL_PAYMENT_STATUSES.includes(payment.value?.status ?? '')
  const refundPending = paymentStore.currentRefunds.some(r => r.status === 'pending')
  return paymentPending || refundPending
}

function startPollingIfNeeded() {
  if (!pollTimeout && needsPolling()) schedulePoll()
}

async function poll() {
  if (POLL_PAYMENT_STATUSES.includes(payment.value?.status ?? '')) {
    await paymentStore.fetchPayment(uid)
  }
  if (payment.value?.status === 'succeeded') {
    await paymentStore.fetchRefunds(uid)
  }
  if (needsPolling()) {
    pollTimeout = setTimeout(poll, 2000)
  } else {
    isPolling.value = false
    pollTimeout = null
  }
}

function schedulePoll() {
  isPolling.value = true
  pollTimeout = setTimeout(poll, 2000)
}

function stopPolling() {
  isPolling.value = false
  if (pollTimeout) {
    clearTimeout(pollTimeout)
    pollTimeout = null
  }
}

async function handleCapture() {
  capturing.value = true
  captureError.value = ''
  try {
    await paymentStore.capture(uid, captureAmount.value ?? undefined)
    startPollingIfNeeded()
  } catch (e: any) {
    captureError.value = e.error ?? 'Something went wrong'
  } finally {
    capturing.value = false
  }
}

async function handleRefund() {
  refunding.value = true
  refundError.value = ''
  try {
    await paymentStore.submitRefund(uid, {
      amount: refundAmount.value!,
      idempotency_key: crypto.randomUUID(),
    })
    refundAmount.value = null
    startPollingIfNeeded()
  } catch (e: any) {
    refundError.value = e.error ?? 'Something went wrong'
  } finally {
    refunding.value = false
  }
}

onMounted(async () => {
  await paymentStore.fetchPayment(uid)
  await paymentStore.fetchRefunds(uid)
  startPollingIfNeeded()
})

onUnmounted(() => {
  stopPolling()
  paymentStore.currentPayment = null
  paymentStore.currentRefunds = []
})
</script>
