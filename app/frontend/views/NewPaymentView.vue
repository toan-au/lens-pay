<template>
  <div class="flex flex-col gap-6 max-w-md">
    <div class="flex items-center gap-3">
      <button @click="router.back()" class="btn-ghost text-xs cursor-pointer">← Back</button>
      <h1 class="text-2xl font-bold">New Payment</h1>
    </div>

    <div class="bg-white rounded-xl border border-gray-200 p-6">
      <form @submit.prevent="handleSubmit" class="flex flex-col gap-4">
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Amount</label>
          <div class="flex gap-2">
            <input
              v-model.number="form.amount"
              type="number"
              min="1"
              required
              placeholder="1000"
              class="input flex-1"
            />
            <span class="input bg-gray-50 text-gray-500 min-w-16 text-center">
              {{ merchantStore.merchant?.currency ?? '...' }}
            </span>
          </div>
          <p class="text-xs text-gray-400">
            Enter amount in {{ currencyHint }}
          </p>
        </div>

        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Idempotency Key</label>
          <div class="flex gap-2">
            <input v-model="form.idempotency_key" type="text" required class="input flex-1 font-mono text-xs" />
            <button type="button" @click="regenerateKey" class="btn-ghost text-xs whitespace-nowrap">Regenerate</button>
          </div>
          <p class="text-xs text-gray-400">Prevents duplicate payments on retries.</p>
        </div>

        <p v-if="error" class="text-sm text-red-500">{{ error }}</p>

        <button type="submit" :disabled="loading" class="btn-primary">
          {{ loading ? 'Creating...' : 'Create Payment' }}
        </button>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useMerchantStore } from '../stores/merchant'
import { usePaymentStore } from '../stores/payments'

const ZERO_DECIMAL_CURRENCIES = ['JPY', 'KRW', 'VND', 'IDR', 'HUF', 'TWD', 'CLP', 'ISK']

const router = useRouter()
const merchantStore = useMerchantStore()
const paymentStore = usePaymentStore()

const loading = ref(false)
const error = ref('')

const currency = computed(() => merchantStore.merchant?.currency ?? 'JPY')

const currencyHint = computed(() =>
  ZERO_DECIMAL_CURRENCIES.includes(currency.value.toUpperCase())
    ? `${currency.value} (e.g. 1000 = ¥1,000)`
    : `${currency.value} minor units (e.g. 1000 = $10.00)`
)

function generateKey(): string {
  return crypto.randomUUID()
}

function regenerateKey() {
  form.idempotency_key = generateKey()
}

const form = reactive({
  amount: null as number | null,
  idempotency_key: generateKey(),
})

async function handleSubmit() {
  if (!form.amount || !merchantStore.merchant) return
  loading.value = true
  error.value = ''
  try {
    const payment = await paymentStore.submitPayment({
      amount: form.amount,
      currency: currency.value,
      idempotency_key: form.idempotency_key,
    })
    router.push(`/payments/${payment.uid}`)
  } catch (e: any) {
    error.value = e.error ?? 'Something went wrong'
  } finally {
    loading.value = false
  }
}
</script>
