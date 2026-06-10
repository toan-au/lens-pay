<template>
  <div class="flex flex-col gap-6 max-w-2xl">
    <button @click="router.back()" class="btn-ghost text-xs w-fit cursor-pointer">← Back</button>

    <div v-if="!dispute" class="text-gray-400 text-sm">Loading...</div>

    <template v-else>
      <div class="flex items-start justify-between">
        <div class="flex flex-col gap-1">
          <h1 class="text-xl font-bold font-mono">{{ dispute.uid }}</h1>
          <p class="text-xs text-gray-400">Opened {{ formatDate(dispute.created_at) }}</p>
        </div>
        <StatusBadge :status="dispute.status" />
      </div>

      <DetailCard>
        <DetailRow label="Reason">
          <span class="text-sm font-medium">{{ formatReason(dispute.reason) }}</span>
        </DetailRow>
        <DetailRow label="Amount">
          <span class="text-sm font-medium">{{ formatAmount(dispute.amount, dispute.currency) }}</span>
        </DetailRow>
        <DetailRow label="Respond by">
          <span class="text-sm" :class="isOverdue ? 'text-red-500 font-medium' : 'text-gray-700'">
            {{ formatDate(dispute.respond_by) }}
          </span>
        </DetailRow>
        <DetailRow v-if="dispute.resolved_at" label="Resolved">
          <span class="text-sm text-gray-700">{{ formatDate(dispute.resolved_at) }}</span>
        </DetailRow>
      </DetailCard>

      <!-- Respond form — only for open/responded disputes within deadline -->
      <div
        v-if="canRespond"
        class="bg-white rounded-xl border border-gray-200 p-5 flex flex-col gap-4"
      >
        <h2 class="font-semibold">Submit Evidence</h2>

        <div v-if="rows.length > 0" class="flex flex-col gap-2">
          <div v-for="(row, i) in rows" :key="i" class="flex gap-2">
            <input
              v-model="row.key"
              placeholder="Key"
              class="input flex-1 font-mono text-sm"
            />
            <input
              v-model="row.value"
              placeholder="Value"
              class="input flex-1 text-sm"
            />
            <button @click="removeRow(i)" class="text-gray-400 hover:text-red-400 px-1 text-lg leading-none">×</button>
          </div>
        </div>

        <button @click="addRow" class="btn-ghost text-xs w-fit">+ Add field</button>

        <p v-if="respondError" class="text-sm text-red-500">{{ respondError }}</p>

        <button @click="handleRespond" :disabled="responding || rows.length === 0" class="btn-primary w-fit">
          {{ responding ? 'Submitting...' : 'Submit evidence' }}
        </button>
      </div>

      <!-- Response history -->
      <div v-if="disputeStore.currentResponses.length > 0" class="flex flex-col gap-3">
        <h2 class="font-semibold">Response history</h2>
        <div
          v-for="resp in disputeStore.currentResponses"
          :key="resp.id"
          class="bg-white rounded-xl border border-gray-200 p-4 flex flex-col gap-2"
        >
          <p class="text-xs text-gray-400">{{ formatDate(resp.created_at) }}</p>
          <div class="flex flex-col gap-1">
            <div v-for="(value, key) in resp.evidence" :key="key" class="flex gap-2 text-sm">
              <span class="font-mono text-gray-500 min-w-32">{{ key }}</span>
              <span class="text-gray-800">{{ value }}</span>
            </div>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useDisputeStore } from '../stores/disputes'
import { formatAmount, formatDate } from '../utils/format'
import { useAsyncAction } from '../composables/useAsyncAction'
import StatusBadge from '../components/ui/StatusBadge.vue'
import DetailCard from '../components/ui/DetailCard.vue'
import DetailRow from '../components/ui/DetailRow.vue'

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

const route = useRoute()
const router = useRouter()
const disputeStore = useDisputeStore()
const uid = route.params.uid as string
const dispute = computed(() => disputeStore.currentDispute)

const isOverdue = computed(() => dispute.value ? new Date(dispute.value.respond_by) < new Date() : false)
const canRespond = computed(() => {
  if (!dispute.value) return false
  return (dispute.value.status === 'open' || dispute.value.status === 'merchant_responded') && !isOverdue.value
})

const rows = ref<{ key: string; value: string }[]>([])

function addRow() { rows.value.push({ key: '', value: '' }) }
function removeRow(i: number) { rows.value.splice(i, 1) }

const { loading: responding, error: respondError, run: runRespond } = useAsyncAction()

async function handleRespond() {
  const evidence = Object.fromEntries(rows.value.filter(r => r.key).map(r => [r.key, r.value]))
  await runRespond(async () => {
    await disputeStore.submitResponse(uid, evidence)
    rows.value = []
  })
}

onMounted(async () => {
  await disputeStore.fetchDispute(uid)
  if (canRespond.value) addRow()
})

onUnmounted(() => {
  disputeStore.currentDispute = null
  disputeStore.currentResponses = []
})
</script>
