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

        <!-- Amount -->
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
          <p class="text-xs text-gray-400">{{ currencyHint }}</p>
        </div>

        <!-- Idempotency key -->
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Idempotency Key</label>
          <div class="flex gap-2">
            <input v-model="form.idempotency_key" type="text" required class="input flex-1 font-mono text-xs" />
            <button type="button" @click="regenerateKey" class="btn-ghost text-xs whitespace-nowrap cursor-pointer">Regenerate</button>
          </div>
          <p class="text-xs text-gray-400">Prevents duplicate payments on retries.</p>
        </div>

        <!-- Customer -->
        <div class="flex flex-col gap-2">
          <div class="flex items-center justify-between">
            <label class="text-sm font-medium">
              Customer <span class="text-gray-400 font-normal">— optional</span>
            </label>
            <button
              v-if="!customerMode"
              type="button"
              @click="customerMode = 'select'"
              class="text-xs text-indigo-500 hover:text-indigo-700 cursor-pointer"
            >
              + Add customer
            </button>
            <button
              v-else-if="!confirmedCustomer"
              type="button"
              @click="clearCustomer"
              class="text-xs text-gray-400 hover:text-gray-600 cursor-pointer"
            >
              Cancel
            </button>
          </div>

          <!-- Confirmed customer card -->
          <div v-if="confirmedCustomer" class="flex items-center justify-between bg-gray-50 rounded-lg border border-gray-200 px-4 py-3">
            <div>
              <p class="text-sm font-medium">{{ confirmedCustomer.name }}</p>
              <p class="text-xs text-gray-500">{{ confirmedCustomer.email }}</p>
            </div>
            <button type="button" @click="clearCustomer" class="text-gray-300 hover:text-red-400 cursor-pointer text-lg leading-none">&times;</button>
          </div>

          <!-- Mode picker + panels -->
          <template v-else-if="customerMode">
            <div class="flex gap-2">
              <button
                type="button"
                @click="customerMode = 'select'"
                class="text-xs px-3 py-1.5 rounded-md border cursor-pointer"
                :class="customerMode === 'select' ? 'bg-gray-100 border-gray-400 font-medium' : 'border-gray-200 text-gray-500'"
              >
                Select existing
              </button>
              <button
                type="button"
                @click="customerMode = 'create'"
                class="text-xs px-3 py-1.5 rounded-md border cursor-pointer"
                :class="customerMode === 'create' ? 'bg-gray-100 border-gray-400 font-medium' : 'border-gray-200 text-gray-500'"
              >
                Create new
              </button>
            </div>

            <!-- Select existing -->
            <template v-if="customerMode === 'select'">
              <input
                v-model="customerSearch"
                type="text"
                placeholder="Search by name or email..."
                class="input"
                autofocus
              />
              <div v-if="filteredCustomers.length" class="border border-gray-200 rounded-lg overflow-hidden">
                <button
                  v-for="c in filteredCustomers"
                  :key="c.uid"
                  type="button"
                  @click="confirmCustomer(c)"
                  class="w-full text-left px-4 py-3 hover:bg-gray-50 border-b last:border-b-0 border-gray-100 cursor-pointer"
                >
                  <p class="text-sm font-medium">{{ c.name }}</p>
                  <p class="text-xs text-gray-500">{{ c.email }}</p>
                </button>
              </div>
              <p v-else-if="customerSearch" class="text-xs text-gray-400">No customers match.</p>
              <p v-else-if="loadingCustomers" class="text-xs text-gray-400">Loading...</p>
              <p v-else class="text-xs text-gray-400">No customers yet.</p>
            </template>

            <!-- Create new -->
            <template v-if="customerMode === 'create'">
              <div class="flex gap-3">
                <div class="flex flex-col gap-1 flex-1">
                  <label class="text-xs font-medium text-gray-600">Name</label>
                  <input v-model="newCustomer.name" type="text" placeholder="Jane Doe" class="input" />
                </div>
                <div class="flex flex-col gap-1 flex-1">
                  <label class="text-xs font-medium text-gray-600">Email</label>
                  <input v-model="newCustomer.email" type="email" placeholder="jane@example.com" class="input" />
                </div>
              </div>
            </template>
          </template>
        </div>

        <!-- Metadata editor -->
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

        <button type="submit" :disabled="loading" class="btn-primary">
          {{ loading ? 'Creating...' : 'Create Payment' }}
        </button>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useMerchantStore } from '../stores/merchant'
import { usePaymentStore } from '../stores/payments'
import { listCustomers, createCustomer } from '../api/customers'
import type { Customer } from '../api/types'

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

const form = reactive({
  amount: 1000 as number | null,
  idempotency_key: crypto.randomUUID(),
})

const metadataRows = reactive<{ key: string; value: string }[]>([
  { key: 'order_id', value: 'order_demo_001' },
])

// Customer state
const allCustomers = ref<Customer[]>([])
const loadingCustomers = ref(false)
const customerMode = ref<null | 'select' | 'create'>(null)
const customerSearch = ref('')
const confirmedCustomer = ref<Customer | null>(null)
const newCustomer = reactive({ name: '', email: '' })

const filteredCustomers = computed(() => {
  const q = customerSearch.value.toLowerCase()
  if (!q) return allCustomers.value
  return allCustomers.value.filter(c =>
    c.name.toLowerCase().includes(q) || c.email.toLowerCase().includes(q)
  )
})

function confirmCustomer(c: Customer) {
  confirmedCustomer.value = c
  customerSearch.value = ''
}

function clearCustomer() {
  confirmedCustomer.value = null
  customerMode.value = null
  customerSearch.value = ''
  newCustomer.name = ''
  newCustomer.email = ''
}

function addMetadataRow() { metadataRows.push({ key: '', value: '' }) }
function removeMetadataRow(i: number) { metadataRows.splice(i, 1) }
function regenerateKey() { form.idempotency_key = crypto.randomUUID() }

function buildMetadata(): Record<string, string> {
  return Object.fromEntries(
    metadataRows.filter(r => r.key.trim()).map(r => [r.key.trim(), r.value])
  )
}

async function resolveCustomerUid(): Promise<string | undefined> {
  if (confirmedCustomer.value) return confirmedCustomer.value.uid
  if (customerMode.value === 'create' && newCustomer.name && newCustomer.email) {
    const customer = await createCustomer({ name: newCustomer.name, email: newCustomer.email })
    confirmedCustomer.value = customer
    return customer.uid
  }
  return undefined
}

async function handleSubmit() {
  if (!form.amount || !merchantStore.merchant) return
  loading.value = true
  error.value = ''
  try {
    const metadata = buildMetadata()
    const customer_uid = await resolveCustomerUid()
    const payment = await paymentStore.submitPayment({
      amount: form.amount,
      currency: currency.value,
      idempotency_key: form.idempotency_key,
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

onMounted(async () => {
  loadingCustomers.value = true
  try {
    const result = await listCustomers({ limit: 100 })
    allCustomers.value = result.customers
  } finally {
    loadingCustomers.value = false
  }
})
</script>
