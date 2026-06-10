<template>
  <div class="flex flex-col gap-6">
    <h1 class="text-2xl font-bold">Disputes</h1>

    <StatusFilterBar :tabs="STATUS_TABS" :model-value="activeFilter" @update:model-value="setFilter" />

    <ResourceTable :loading="loading" :is-empty="disputeStore.disputes.length === 0" :cols="5" empty-text="No disputes yet.">
      <template #head>
        <th class="text-left px-4 py-3 font-medium text-gray-500">ID</th>
        <th class="text-left px-4 py-3 font-medium text-gray-500">Reason</th>
        <th class="text-left px-4 py-3 font-medium text-gray-500">Amount</th>
        <th class="text-left px-4 py-3 font-medium text-gray-500">Status</th>
        <th class="text-left px-4 py-3 font-medium text-gray-500">Respond by</th>
      </template>
      <template #body>
        <tr
          v-for="dispute in disputeStore.disputes"
          :key="dispute.uid"
          @click="router.push(`/disputes/${dispute.uid}`)"
          class="border-t border-gray-100 hover:bg-gray-50 cursor-pointer transition-colors"
        >
          <td class="px-4 py-3 font-mono text-xs text-gray-500">{{ dispute.uid.slice(0, 16) }}</td>
          <td class="px-4 py-3 text-sm">{{ formatReason(dispute.reason) }}</td>
          <td class="px-4 py-3 font-medium">{{ formatAmount(dispute.amount, dispute.currency) }}</td>
          <td class="px-4 py-3"><StatusBadge :status="dispute.status" /></td>
          <td class="px-4 py-3 text-gray-500 text-xs">{{ formatDate(dispute.respond_by) }}</td>
        </tr>
      </template>
    </ResourceTable>

    <div v-if="disputeStore.nextCursor" class="flex justify-center">
      <button @click="loadMore" :disabled="loading" class="btn-ghost">
        {{ loading ? 'Loading...' : 'Load more' }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useDisputeStore } from '../stores/disputes'
import { formatAmount, formatDate } from '../utils/format'
import ResourceTable from '../components/ui/ResourceTable.vue'
import StatusBadge from '../components/ui/StatusBadge.vue'
import StatusFilterBar from '../components/ui/StatusFilterBar.vue'

const STATUS_TABS = [
  { label: 'All', value: '' },
  { label: 'Open', value: 'open' },
  { label: 'Responded', value: 'merchant_responded' },
  { label: 'Won', value: 'won' },
  { label: 'Lost', value: 'lost' },
]

const REASON_LABELS: Record<string, string> = {
  fraudulent: 'Fraudulent',
  unrecognized: 'Unrecognized',
  duplicate: 'Duplicate',
  product_not_received: 'Product not received',
  product_unacceptable: 'Product unacceptable',
}

function formatReason(reason: string): string {
  return REASON_LABELS[reason] ?? reason
}

const router = useRouter()
const disputeStore = useDisputeStore()
const loading = ref(false)
const activeFilter = ref('')

async function load(filter: string, cursor?: string) {
  loading.value = true
  try {
    await disputeStore.fetchDisputes({ status: filter || undefined, cursor })
  } finally {
    loading.value = false
  }
}

async function setFilter(value: string) {
  activeFilter.value = value
  await load(value)
}

async function loadMore() {
  if (disputeStore.nextCursor) await load(activeFilter.value, disputeStore.nextCursor)
}

onMounted(() => load(''))
</script>
