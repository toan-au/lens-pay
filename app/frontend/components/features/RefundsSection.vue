<template>
  <div class="flex flex-col gap-4">
    <h2 class="font-semibold">Refunds</h2>

    <div v-if="refunds.length > 0" class="bg-white rounded-xl border border-gray-200 divide-y divide-gray-100">
      <div
        v-for="refund in refunds"
        :key="refund.uid"
        class="flex items-center justify-between px-5 py-4"
      >
        <div class="flex flex-col gap-0.5">
          <span class="text-sm font-medium">{{ formatAmount(refund.amount, currency) }}</span>
          <span class="text-xs text-gray-400">{{ formatDate(refund.created_at) }}</span>
        </div>
        <StatusBadge :status="refund.status" />
      </div>
    </div>

    <p v-else class="text-sm text-gray-400">No refunds yet.</p>

    <template v-if="remainingAmount > 0">
      <div class="bg-white rounded-xl border border-gray-200 p-5 flex flex-col gap-4">
        <h3 class="font-semibold text-sm">Issue Refund</h3>
        <form @submit.prevent="handle" class="flex flex-col gap-3">
          <div class="flex flex-col gap-1">
            <label class="text-sm font-medium">
              Amount
              <span class="text-gray-400 font-normal">— max {{ formatAmount(remainingAmount, currency) }}</span>
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
              <span class="input bg-gray-50 text-gray-500 min-w-16 text-center">{{ currency }}</span>
            </div>
          </div>
          <p v-if="error" class="text-sm text-red-500">{{ error }}</p>
          <button type="submit" :disabled="loading" class="btn-primary">
            {{ loading ? 'Refunding...' : 'Issue Refund' }}
          </button>
        </form>
      </div>
    </template>

    <p v-else class="text-sm text-gray-500">Fully refunded.</p>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { formatAmount, formatDate } from '../../utils/format'
import { useAsyncAction } from '../../composables/useAsyncAction'
import StatusBadge from '../ui/StatusBadge.vue'
import type { Refund } from '../../api/types'

const props = defineProps<{
  capturedAmount: number
  currency: string
  refunds: Refund[]
  onRefund: (amount: number) => Promise<void>
}>()

const { loading, error, run } = useAsyncAction()
const refundAmount = ref<number | null>(null)

const remainingAmount = computed(() => {
  const refunded = props.refunds
    .filter(r => r.status === 'succeeded')
    .reduce((sum, r) => sum + r.amount, 0)
  return props.capturedAmount - refunded
})

function handle() {
  run(async () => {
    await props.onRefund(refundAmount.value!)
    refundAmount.value = null
  })
}
</script>
