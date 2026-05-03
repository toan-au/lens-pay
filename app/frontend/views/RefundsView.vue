<template>
  <div class="flex flex-col gap-6">
    <h1 class="text-2xl font-bold">Refunds</h1>

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
            <th class="text-left px-4 py-3 font-medium text-gray-500">Payment</th>
            <th class="text-left px-4 py-3 font-medium text-gray-500">Date</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading && paymentStore.allRefunds.length === 0">
            <td colspan="5" class="px-4 py-10 text-center text-gray-400">Loading...</td>
          </tr>
          <tr v-else-if="paymentStore.allRefunds.length === 0">
            <td colspan="5" class="px-4 py-10 text-center text-gray-400">No refunds yet.</td>
          </tr>
          <tr
            v-for="refund in paymentStore.allRefunds"
            :key="refund.uid"
            @click="refund.payment_uid && router.push(`/payments/${refund.payment_uid}`)"
            class="border-t border-gray-100 hover:bg-gray-50 cursor-pointer transition-colors"
          >
            <td class="px-4 py-3 font-mono text-xs text-gray-500">{{ refund.uid.slice(0, 12) }}</td>
            <td class="px-4 py-3 font-medium">{{ formatAmount(refund.amount, refund.currency ?? 'JPY') }}</td>
            <td class="px-4 py-3">
              <span :class="statusClass(refund.status)">{{ refund.status }}</span>
            </td>
            <td class="px-4 py-3 font-mono text-xs text-gray-500">
              {{ refund.payment_uid?.slice(0, 12) ?? '—' }}
            </td>
            <td class="px-4 py-3 text-gray-500 text-xs">{{ formatDate(refund.created_at) }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="paymentStore.allRefundsNextCursor" class="flex justify-center">
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
import { formatAmount, formatDate, statusClass } from '../utils/format'

const STATUS_TABS = [
  { label: 'All', value: '' },
  { label: 'Pending', value: 'pending' },
  { label: 'Succeeded', value: 'succeeded' },
  { label: 'Declined', value: 'declined' },
]

const router = useRouter()
const paymentStore = usePaymentStore()
const loading = ref(false)
const activeFilter = ref('')

async function load(filter: string, cursor?: string) {
  loading.value = true
  try {
    await paymentStore.fetchAllRefunds({ status: filter || undefined, cursor })
  } finally {
    loading.value = false
  }
}

async function setFilter(value: string) {
  activeFilter.value = value
  await load(value)
}

async function loadMore() {
  if (paymentStore.allRefundsNextCursor) {
    await load(activeFilter.value, paymentStore.allRefundsNextCursor)
  }
}

onMounted(() => load(''))
</script>
