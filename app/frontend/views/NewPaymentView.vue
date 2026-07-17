<template>
  <div class="flex flex-col gap-6 max-w-md">
    <div class="flex items-center gap-3">
      <button @click="router.back()" class="btn-ghost text-xs cursor-pointer">← Back</button>
      <h1 class="text-2xl font-bold">New Payment</h1>
    </div>

    <div class="bg-amber-50 border border-amber-200 rounded-xl px-5 py-4 text-sm text-amber-800">
      In production, payments are created by your backend via the API, not through a UI. This form is here so you can generate test payments and explore the dashboard.
      See the <a href="/api-docs" target="_blank" class="underline font-medium hover:text-amber-900">API documentation</a> to call this endpoint directly.
    </div>

    <div class="bg-white rounded-xl border border-gray-200 p-6">
      <form @submit.prevent="handleSubmit" class="flex flex-col gap-4">

        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Amount</label>
          <div class="flex gap-2">
            <input
              v-model.number="form.amount"
              type="number"
              :min="isZeroDecimal ? 1 : 0.01"
              :step="isZeroDecimal ? 1 : 0.01"
              required
              :placeholder="isZeroDecimal ? '1000' : '10.00'"
              class="input flex-1"
            />
            <span class="input bg-gray-50 text-gray-500 min-w-16 text-center">
              {{ merchantStore.merchant?.currency ?? '...' }}
            </span>
          </div>
          <p v-if="form.amount" class="text-sm font-medium text-indigo-600">
            = {{ formatAmount(toMinorUnits(form.amount, currency), currency) }}
          </p>
          <p v-else class="text-xs text-gray-400">{{ currencyHint }}</p>
        </div>

        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Payment Method</label>
          <div class="grid grid-cols-3 gap-2">
            <button
              v-for="m in PAYMENT_METHODS"
              :key="m.value"
              type="button"
              @click="form.payment_method = m.value"
              class="rounded-lg border px-3 py-2 text-sm cursor-pointer transition-colors"
              :class="form.payment_method === m.value
                ? 'border-indigo-500 bg-indigo-50 text-indigo-700 font-medium'
                : 'border-gray-200 text-gray-600 hover:border-gray-300'"
            >
              {{ m.label }}
            </button>
          </div>
          <p class="text-xs text-gray-400">{{ methodHint }}</p>
        </div>

        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Idempotency Key</label>
          <div class="flex gap-2">
            <input v-model="form.idempotency_key" type="text" required class="input flex-1 font-mono text-xs" />
            <button type="button" @click="regenerateKey" class="btn-ghost text-xs whitespace-nowrap cursor-pointer">Regenerate</button>
          </div>
          <p class="text-xs text-gray-400">Prevents duplicate payments on retries.</p>
        </div>

        <CustomerPicker ref="picker" />

        <div class="flex flex-col gap-2">
          <div class="flex items-center justify-between">
            <label class="text-sm font-medium">Metadata</label>
            <button type="button" @click="addMetadataRow" class="text-xs text-indigo-500 hover:text-indigo-700 cursor-pointer">+ Add field</button>
          </div>
          <p class="text-xs text-gray-400">Attach arbitrary key-value data to this payment — useful for linking to an order ID, customer, or any internal reference.</p>
          <div v-if="metadataRows.length > 0" class="flex flex-col gap-2">
            <div v-for="(row, i) in metadataRows" :key="i" class="flex gap-2 items-center">
              <input v-model="row.key" type="text" placeholder="key" class="input flex-1 font-mono text-xs" />
              <input v-model="row.value" type="text" placeholder="value" class="input flex-1 font-mono text-xs" />
              <button type="button" @click="removeMetadataRow(i)" class="text-gray-300 hover:text-red-400 cursor-pointer text-lg leading-none">&times;</button>
            </div>
          </div>
        </div>

        <p v-if="error" class="text-sm text-red-500">{{ error }}</p>

        <AmountButton
          label="Create Payment"
          loading-label="Creating..."
          :amount="form.amount != null ? toMinorUnits(form.amount, currency) : null"
          :currency="currency"
          :loading="loading"
        />
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useMerchantStore } from '../stores/merchant'
import { usePaymentStore } from '../stores/payments'
import { ZERO_DECIMAL_CURRENCIES, formatAmount, toMinorUnits } from '../utils/format'
import CustomerPicker from '../components/features/CustomerPicker.vue'
import AmountButton from '../components/ui/AmountButton.vue'
import type { PaymentMethod } from '../api/types'

const router = useRouter()
const merchantStore = useMerchantStore()
const paymentStore = usePaymentStore()

const loading = ref(false)
const error = ref('')
const picker = ref<InstanceType<typeof CustomerPicker> | null>(null)

const currency = computed(() => merchantStore.merchant?.currency ?? 'JPY')
const isZeroDecimal = computed(() => ZERO_DECIMAL_CURRENCIES.includes(currency.value.toUpperCase()))
const currencyHint = computed(() =>
  isZeroDecimal.value
    ? `Enter the exact amount (e.g. 1000 = ¥1,000)`
    : `Enter the natural amount (e.g. 10.00 = $10.00)`
)

const PAYMENT_METHODS = [
  { value: 'card', label: 'Card' },
  { value: 'konbini', label: 'Konbini' },
  { value: 'bank_transfer', label: 'Bank Transfer' },
] as const

const form = reactive({
  amount: null as number | null,
  idempotency_key: crypto.randomUUID(),
  payment_method: 'card' as PaymentMethod,
})

const methodHint = computed(() => ({
  card: 'Authorized by the card network, then captured by you.',
  konbini: 'Customer pays cash at a convenience store within 3 days. No card authorization.',
  bank_transfer: 'Customer wires funds within 7 days. No card authorization.',
}[form.payment_method]))

const metadataRows = reactive<{ key: string; value: string }[]>([
  { key: 'order_id', value: 'order_demo_001' },
])

function addMetadataRow() { metadataRows.push({ key: '', value: '' }) }
function removeMetadataRow(i: number) { metadataRows.splice(i, 1) }
function regenerateKey() { form.idempotency_key = crypto.randomUUID() }

function buildMetadata(): Record<string, string> {
  return Object.fromEntries(
    metadataRows.filter(r => r.key.trim()).map(r => [r.key.trim(), r.value])
  )
}

async function handleSubmit() {
  if (!form.amount || !merchantStore.merchant) return
  loading.value = true
  error.value = ''
  try {
    const metadata = buildMetadata()
    const customer_uid = await picker.value?.resolve()
    const payment = await paymentStore.submitPayment({
      amount: toMinorUnits(form.amount!, currency.value),
      currency: currency.value,
      idempotency_key: form.idempotency_key,
      payment_method: form.payment_method,
      ...(customer_uid && { customer_uid }),
      ...(Object.keys(metadata).length > 0 && { metadata }),
    })
    router.push(`/payments/${payment.uid}`)
  } catch (e: any) {
    error.value = e.errors?.join(', ') ?? e.error ?? 'Something went wrong'
  } finally {
    loading.value = false
  }
}
</script>
