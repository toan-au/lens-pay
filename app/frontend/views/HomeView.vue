<template>
  <div class="flex flex-col gap-6">
    <div class="flex items-center justify-between">
      <h1 class="text-2xl font-bold">Payments</h1>
      <RouterLink to="/payments/new" class="btn-primary">+ New Payment</RouterLink>
    </div>

    <StatusFilterBar :tabs="STATUS_TABS" :model-value="activeFilter" @update:model-value="setFilter" />

    <ResourceTable :loading="loading" :is-empty="paymentStore.payments.length === 0" :cols="4">
      <template #head>
        <th class="text-left px-4 py-3 font-medium text-gray-500">ID</th>
        <th class="text-left px-4 py-3 font-medium text-gray-500">Amount</th>
        <th class="text-left px-4 py-3 font-medium text-gray-500">Status</th>
        <th class="text-left px-4 py-3 font-medium text-gray-500">Date</th>
      </template>
      <template #empty>
        No payments yet.
        <RouterLink to="/payments/new" class="text-indigo-500 underline ml-1">Create one</RouterLink>
      </template>
      <template #body>
        <tr
          v-for="payment in paymentStore.payments"
          :key="payment.uid"
          @click="router.push(`/payments/${payment.uid}`)"
          class="border-t border-gray-100 hover:bg-gray-50 cursor-pointer transition-colors"
        >
          <td class="px-4 py-3 font-mono text-xs text-gray-500">{{ payment.uid.slice(0, 12) }}</td>
          <td class="px-4 py-3 font-medium">{{ formatAmount(payment.amount, payment.currency) }}</td>
          <td class="px-4 py-3"><StatusBadge :status="payment.status" /></td>
          <td class="px-4 py-3 text-gray-500 text-xs">{{ formatDate(payment.created_at) }}</td>
        </tr>
      </template>
    </ResourceTable>

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
import { formatAmount, formatDate } from '../utils/format'
import ResourceTable from '../components/ui/ResourceTable.vue'
import StatusBadge from '../components/ui/StatusBadge.vue'
import StatusFilterBar from '../components/ui/StatusFilterBar.vue'

const STATUS_TABS = [
  { label: 'All', value: '' },
  { label: 'Pending', value: 'pending' },
  { label: 'Authorized', value: 'authorized' },
  { label: 'Processing', value: 'processing' },
  { label: 'Succeeded', value: 'succeeded' },
  { label: 'Declined', value: 'declined' },
  { label: 'Cancelled', value: 'cancelled' },
  { label: 'Expired', value: 'expired' },
]

const router = useRouter()
const paymentStore = usePaymentStore()
const loading = ref(false)
const activeFilter = ref('')

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
  if (paymentStore.nextCursor) await load(activeFilter.value, paymentStore.nextCursor)
}

onMounted(() => load(''))
</script>
