<template>
  <div class="flex flex-col gap-6">
    <div class="flex items-center justify-between">
      <h1 class="text-2xl font-bold">Payments</h1>
      <RouterLink to="/payments/new" class="btn-primary">+ New Payment</RouterLink>
    </div>

    <!-- Demo API key banner -->
    <div v-if="merchantStore.apiKey" class="flex items-center justify-between bg-red-50 border border-red-200 rounded-lg px-4 py-3 gap-4">
      <div class="flex flex-col gap-0.5">
        <p class="text-xs font-medium text-red-600">Demo mode — API key (not shown in production)</p>
        <code class="text-xs text-red-800 break-all">{{ merchantStore.apiKey }}</code>
      </div>
      <button @click="copyKey" class="btn-ghost text-xs whitespace-nowrap">
        {{ keyCopied ? 'Copied!' : 'Copy' }}
      </button>
    </div>

    <!-- Status filter -->
    <div class="flex gap-2 flex-wrap">
      <button
        v-for="tab in STATUS_TABS"
        :key="tab.value"
        @click="setFilter(tab.value)"
        class="btn-ghost text-xs"
        :class="{ 'bg-gray-100 border-gray-400': activeFilter === tab.value }"
      >
        {{ tab.label }}
      </button>
    </div>

    <!-- Table -->
    <div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
      <table class="w-full text-sm">
        <thead class="border-b border-gray-100 bg-gray-50">
          <tr>
            <th class="text-left px-4 py-3 font-medium text-gray-500">ID</th>
            <th class="text-left px-4 py-3 font-medium text-gray-500">Amount</th>
            <th class="text-left px-4 py-3 font-medium text-gray-500">Status</th>
            <th class="text-left px-4 py-3 font-medium text-gray-500">Date</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading && paymentStore.payments.length === 0">
            <td colspan="4" class="px-4 py-10 text-center text-gray-400">Loading...</td>
          </tr>
          <tr v-else-if="paymentStore.payments.length === 0">
            <td colspan="4" class="px-4 py-10 text-center text-gray-400">
              No payments yet.
              <RouterLink to="/payments/new" class="text-indigo-500 underline ml-1">Create one</RouterLink>
            </td>
          </tr>
          <tr
            v-for="payment in paymentStore.payments"
            :key="payment.uid"
            @click="router.push(`/payments/${payment.uid}`)"
            class="border-t border-gray-100 hover:bg-gray-50 cursor-pointer transition-colors"
          >
            <td class="px-4 py-3 font-mono text-xs text-gray-500">{{ payment.uid.slice(0, 12) }}</td>
            <td class="px-4 py-3 font-medium">{{ formatAmount(payment.amount, payment.currency) }}</td>
            <td class="px-4 py-3">
              <span :class="statusClass(payment.status)">{{ payment.status }}</span>
            </td>
            <td class="px-4 py-3 text-gray-500 text-xs">{{ formatDate(payment.created_at) }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="paymentStore.nextCursor" class="flex justify-center">
      <button @click="loadMore" :disabled="loading" class="btn-ghost">
        {{ loading ? 'Loading...' : 'Load more' }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { usePaymentStore } from '../stores/payments'
import { useMerchantStore } from '../stores/merchant'
import { formatAmount, formatDate, statusClass } from '../utils/format'

const STATUS_TABS = [
  { label: 'All', value: '' },
  { label: 'Pending', value: 'pending' },
  { label: 'Authorized', value: 'authorized' },
  { label: 'Processing', value: 'processing' },
  { label: 'Succeeded', value: 'succeeded' },
  { label: 'Declined', value: 'declined' },
]

const router = useRouter()
const paymentStore = usePaymentStore()
const merchantStore = useMerchantStore()
const loading = ref(false)
const activeFilter = ref('')
const keyCopied = ref(false)

function copyKey() {
  if (!merchantStore.apiKey) return
  navigator.clipboard.writeText(merchantStore.apiKey)
  keyCopied.value = true
  setTimeout(() => (keyCopied.value = false), 2000)
}

async function load(filter: string, cursor?: string) {
  loading.value = true
  try {
    await paymentStore.fetchPayments({ status: filter || undefined, cursor })
  } finally {
    loading.value = false
  }
}

async function setFilter(value: string) {
  activeFilter.value = value
  await load(value)
}

async function loadMore() {
  if (paymentStore.nextCursor) {
    await load(activeFilter.value, paymentStore.nextCursor)
  }
}

onMounted(() => load(''))
</script>
