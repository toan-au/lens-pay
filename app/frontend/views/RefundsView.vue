<template>
  <div class="flex flex-col gap-6">
    <h1 class="text-2xl font-bold">Refunds</h1>

    <StatusFilterBar :tabs="STATUS_TABS" :model-value="activeFilter" @update:model-value="setFilter" />

    <ResourceTable :loading="loading" :is-empty="paymentStore.allRefunds.length === 0" :cols="5" empty-text="No refunds yet.">
      <template #head>
        <th class="text-left px-4 py-3 font-medium text-gray-500">ID</th>
        <th class="text-left px-4 py-3 font-medium text-gray-500">Amount</th>
        <th class="text-left px-4 py-3 font-medium text-gray-500">Status</th>
        <th class="text-left px-4 py-3 font-medium text-gray-500">Payment</th>
        <th class="text-left px-4 py-3 font-medium text-gray-500">Date</th>
      </template>
      <template #body>
        <tr
          v-for="refund in paymentStore.allRefunds"
          :key="refund.uid"
          @click="refund.payment_uid && router.push(`/payments/${refund.payment_uid}`)"
          class="border-t border-gray-100 hover:bg-gray-50 cursor-pointer transition-colors"
        >
          <td class="px-4 py-3 font-mono text-xs text-gray-500">{{ refund.uid.slice(0, 12) }}</td>
          <td class="px-4 py-3 font-medium">{{ formatAmount(refund.amount, refund.currency ?? 'JPY') }}</td>
          <td class="px-4 py-3"><StatusBadge :status="refund.status" /></td>
          <td class="px-4 py-3 font-mono text-xs text-gray-500">{{ refund.payment_uid?.slice(0, 12) ?? '—' }}</td>
          <td class="px-4 py-3 text-gray-500 text-xs">{{ formatDate(refund.created_at) }}</td>
        </tr>
      </template>
    </ResourceTable>

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
import { formatAmount, formatDate } from '../utils/format'
import ResourceTable from '../components/ui/ResourceTable.vue'
import StatusBadge from '../components/ui/StatusBadge.vue'
import StatusFilterBar from '../components/ui/StatusFilterBar.vue'

const STATUS_TABS = [
  { label: 'All', value: '' },
  { label: 'Pending', value: 'pending' },
  { label: 'Succeeded', value: 'succeeded' },
  { label: 'Failed', value: 'failed' },
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
  if (paymentStore.allRefundsNextCursor) await load(activeFilter.value, paymentStore.allRefundsNextCursor)
}

onMounted(() => load(''))
</script>
