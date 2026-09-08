<template>
  <div class="flex flex-col gap-2">
    <div class="flex items-center justify-between">
      <span :id="labelId" class="text-sm font-medium">
        Customer <span class="text-gray-500 font-normal">— optional</span>
      </span>
      <button
        v-if="!mode"
        type="button"
        @click="mode = 'select'"
        class="text-xs text-indigo-600 hover:text-indigo-800 cursor-pointer"
      >
        + Add customer
      </button>
      <button
        v-else-if="!confirmed"
        type="button"
        @click="clear"
        class="text-xs text-gray-500 hover:text-gray-700 cursor-pointer"
      >
        Cancel
      </button>
    </div>

    <!-- Confirmed customer card -->
    <div v-if="confirmed" class="flex items-center justify-between bg-gray-50 rounded-lg border border-gray-200 px-4 py-3">
      <div>
        <p class="text-sm font-medium">{{ confirmed.name }}</p>
        <p class="text-xs text-gray-500">{{ confirmed.email }}</p>
      </div>
      <button
        type="button"
        @click="clear"
        aria-label="Remove selected customer"
        class="text-gray-400 hover:text-red-500 cursor-pointer text-lg leading-none"
      >
        &times;
      </button>
    </div>

    <!-- Mode picker + panels -->
    <template v-else-if="mode">
      <div class="flex gap-2" role="group" :aria-labelledby="labelId">
        <button
          type="button"
          :aria-pressed="mode === 'select'"
          @click="mode = 'select'"
          class="text-xs px-3 py-1.5 rounded-md border cursor-pointer focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-500"
          :class="mode === 'select' ? 'bg-gray-100 border-gray-400 font-medium' : 'border-gray-200 text-gray-500'"
        >
          Select existing
        </button>
        <button
          type="button"
          :aria-pressed="mode === 'create'"
          @click="mode = 'create'"
          class="text-xs px-3 py-1.5 rounded-md border cursor-pointer focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-500"
          :class="mode === 'create' ? 'bg-gray-100 border-gray-400 font-medium' : 'border-gray-200 text-gray-500'"
        >
          Create new
        </button>
      </div>

      <template v-if="mode === 'select'">
        <input
          v-model="search"
          type="text"
          placeholder="Search by name or email..."
          aria-label="Search customers by name or email"
          class="input"
          autofocus
        />
        <div v-if="filtered.length" class="border border-gray-200 rounded-lg overflow-hidden">
          <button
            v-for="c in filtered"
            :key="c.uid"
            type="button"
            @click="confirm(c)"
            class="w-full text-left px-4 py-3 hover:bg-gray-50 border-b last:border-b-0 border-gray-100 cursor-pointer"
          >
            <p class="text-sm font-medium">{{ c.name }}</p>
            <p class="text-xs text-gray-500">{{ c.email }}</p>
          </button>
        </div>
        <p v-else-if="search" class="text-xs text-gray-500">No customers match.</p>
        <p v-else-if="loading" class="text-xs text-gray-500">Loading...</p>
        <p v-else class="text-xs text-gray-500">No customers yet.</p>
      </template>

      <template v-if="mode === 'create'">
        <div class="flex gap-3">
          <div class="flex flex-col gap-1 flex-1">
            <label :for="draftNameId" class="text-xs font-medium text-gray-600">Name</label>
            <input :id="draftNameId" v-model="draft.name" type="text" placeholder="Jane Doe" class="input" />
          </div>
          <div class="flex flex-col gap-1 flex-1">
            <label :for="draftEmailId" class="text-xs font-medium text-gray-600">Email</label>
            <input :id="draftEmailId" v-model="draft.email" type="email" placeholder="jane@example.com" class="input" />
          </div>
        </div>
      </template>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, useId } from 'vue'
import { listCustomers, createCustomer } from '../../api/customers'
import type { Customer } from '../../api/types'

const labelId = useId()
const draftNameId = useId()
const draftEmailId = useId()

const mode = ref<null | 'select' | 'create'>(null)
const confirmed = ref<Customer | null>(null)
const search = ref('')
const draft = reactive({ name: '', email: '' })
const all = ref<Customer[]>([])
const loading = ref(false)

const filtered = computed(() => {
  const q = search.value.toLowerCase()
  if (!q) return all.value
  return all.value.filter(c => c.name.toLowerCase().includes(q) || c.email.toLowerCase().includes(q))
})

function confirm(c: Customer) {
  confirmed.value = c
  search.value = ''
}

function clear() {
  confirmed.value = null
  mode.value = null
  search.value = ''
  draft.name = ''
  draft.email = ''
}

async function resolve(): Promise<string | undefined> {
  if (confirmed.value) return confirmed.value.uid
  if (mode.value === 'create' && draft.name && draft.email) {
    const customer = await createCustomer({ name: draft.name, email: draft.email })
    confirmed.value = customer
    return customer.uid
  }
  return undefined
}

onMounted(async () => {
  loading.value = true
  try {
    const result = await listCustomers({ limit: 100 })
    all.value = result.customers
  } finally {
    loading.value = false
  }
})

defineExpose({ resolve })
</script>
