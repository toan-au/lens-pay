<template>
  <div class="flex flex-col gap-6">
    <div class="flex items-center justify-between">
      <h1 class="text-2xl font-bold">Customers</h1>
      <button @click="showForm = !showForm" class="btn-primary">
        {{ showForm ? 'Cancel' : '+ New Customer' }}
      </button>
    </div>

    <div v-if="showForm" class="bg-white rounded-xl border border-gray-200 p-6">
      <form @submit.prevent="handleCreate" class="flex flex-col gap-4">
        <h2 class="font-semibold">New Customer</h2>
        <div class="flex gap-4">
          <div class="flex flex-col gap-1 flex-1">
            <label class="text-sm font-medium">Name</label>
            <input v-model="form.name" type="text" required placeholder="Jane Doe" class="input" />
          </div>
          <div class="flex flex-col gap-1 flex-1">
            <label class="text-sm font-medium">Email</label>
            <input v-model="form.email" type="email" required placeholder="jane@example.com" class="input" />
          </div>
        </div>
        <p v-if="createError" class="text-sm text-red-500">{{ createError }}</p>
        <div class="flex justify-end">
          <button type="submit" :disabled="creating" class="btn-primary">
            {{ creating ? 'Creating...' : 'Create Customer' }}
          </button>
        </div>
      </form>
    </div>

    <ResourceTable :loading="loading" :is-empty="customers.length === 0" :cols="4" empty-text="No customers yet.">
      <template #head>
        <th class="text-left px-4 py-3 font-medium text-gray-500">Name</th>
        <th class="text-left px-4 py-3 font-medium text-gray-500">Email</th>
        <th class="text-left px-4 py-3 font-medium text-gray-500">ID</th>
        <th class="text-left px-4 py-3 font-medium text-gray-500">Created</th>
      </template>
      <template #body>
        <tr
          v-for="customer in customers"
          :key="customer.uid"
          @click="router.push(`/customers/${customer.uid}`)"
          class="border-t border-gray-100 hover:bg-gray-50 cursor-pointer transition-colors"
        >
          <td class="px-4 py-3 font-medium">{{ customer.name }}</td>
          <td class="px-4 py-3 text-gray-500">{{ customer.email }}</td>
          <td class="px-4 py-3 font-mono text-xs text-gray-400">{{ customer.uid.slice(0, 16) }}</td>
          <td class="px-4 py-3 text-gray-500 text-xs">{{ formatDate(customer.created_at) }}</td>
        </tr>
      </template>
    </ResourceTable>

    <div v-if="nextCursor" class="flex justify-center">
      <button @click="loadMore" :disabled="loading" class="btn-ghost">
        {{ loading ? 'Loading...' : 'Load more' }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { listCustomers, createCustomer } from '../api/customers'
import { formatDate } from '../utils/format'
import { useAsyncAction } from '../composables/useAsyncAction'
import ResourceTable from '../components/ui/ResourceTable.vue'
import type { Customer } from '../api/types'

const router = useRouter()

const customers = ref<Customer[]>([])
const nextCursor = ref<string | null>(null)
const loading = ref(false)
const showForm = ref(false)
const form = reactive({ name: '', email: '' })

const { loading: creating, error: createError, run: runCreate } = useAsyncAction()

async function load(cursor?: string) {
  loading.value = true
  try {
    const result = await listCustomers({ cursor })
    customers.value = cursor ? [...customers.value, ...result.customers] : result.customers
    nextCursor.value = result.next_cursor
  } finally {
    loading.value = false
  }
}

async function loadMore() {
  if (nextCursor.value) await load(nextCursor.value)
}

async function handleCreate() {
  await runCreate(async () => {
    const customer = await createCustomer({ name: form.name, email: form.email })
    customers.value = [customer, ...customers.value]
    form.name = ''
    form.email = ''
    showForm.value = false
    router.push(`/customers/${customer.uid}`)
  })
}

onMounted(() => load())
</script>
