<template>
  <div class="bg-white rounded-xl border border-gray-200 p-5 flex flex-col gap-4">
    <h2 class="font-semibold">Capture Payment</h2>
    <form @submit.prevent="handle" class="flex flex-col gap-3">
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium">
          Amount
          <span class="text-gray-400 font-normal">— leave blank to capture full amount</span>
        </label>
        <div class="flex gap-2">
          <input
            v-model.number="naturalAmount"
            type="number"
            :min="isZeroDecimal ? 1 : 0.01"
            :step="isZeroDecimal ? 1 : 0.01"
            :max="naturalMax"
            :placeholder="String(naturalMax)"
            class="input flex-1"
          />
          <span class="input bg-gray-50 text-gray-500 min-w-16 text-center">{{ currency }}</span>
        </div>
      </div>
      <p v-if="error" class="text-sm text-red-500">{{ error }}</p>
      <AmountButton
        label="Capture"
        loading-label="Capturing..."
        :amount="toMinorUnits(naturalAmount ?? naturalMax, currency)"
        :currency="currency"
        :loading="loading"
      />
    </form>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { ZERO_DECIMAL_CURRENCIES, toMinorUnits, fromMinorUnits } from '../../utils/format'
import { useAsyncAction } from '../../composables/useAsyncAction'
import AmountButton from '../ui/AmountButton.vue'

const props = defineProps<{
  amount: number
  currency: string
  onCapture: (amount?: number) => Promise<void>
}>()

const { loading, error, run } = useAsyncAction()
const naturalAmount = ref<number | null>(null)

const isZeroDecimal = computed(() => ZERO_DECIMAL_CURRENCIES.includes(props.currency.toUpperCase()))
const naturalMax = computed(() => fromMinorUnits(props.amount, props.currency))

function handle() {
  run(async () => {
    const minor = naturalAmount.value != null ? toMinorUnits(naturalAmount.value, props.currency) : undefined
    await props.onCapture(minor)
    naturalAmount.value = null
  })
}
</script>
