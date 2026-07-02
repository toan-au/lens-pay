<template>
  <div class="flex flex-col gap-6 max-w-2xl">
    <button @click="router.back()" class="btn-ghost text-xs w-fit cursor-pointer">← Back</button>

    <div v-if="!customer" class="text-gray-400 text-sm">Loading...</div>

    <template v-else>
      <div class="flex items-start justify-between">
        <div>
          <h1 class="text-xl font-bold">{{ customer.name }}</h1>
          <p class="text-sm text-gray-500 mt-0.5">{{ customer.email }}</p>
        </div>
        <span v-if="customer.deleted_at" class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-700">
          deleted
        </span>
        <span v-else class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-700">
          active
        </span>
      </div>

      <DetailCard>
        <DetailRow label="UID">
          <span class="text-xs font-mono text-gray-600">{{ customer.uid }}</span>
        </DetailRow>
        <DetailRow label="Created">
          <span class="text-sm">{{ formatDate(customer.created_at) }}</span>
        </DetailRow>
        <DetailRow v-if="customer.deleted_at" label="Deleted">
          <span class="text-sm text-red-500">{{ formatDate(customer.deleted_at) }}</span>
        </DetailRow>
        <template v-if="Object.keys(customer.metadata ?? {}).length > 0">
          <DetailRow v-for="(value, key) in customer.metadata" :key="key" :label="String(key)" label-class="font-mono">
            <span class="text-sm text-gray-700 font-mono">{{ value }}</span>
          </DetailRow>
        </template>
      </DetailCard>

      <div v-if="!customer.deleted_at" class="bg-white rounded-xl border border-gray-200 p-5 flex flex-col gap-4">
        <div class="flex items-center justify-between">
          <h2 class="font-semibold">Edit</h2>
          <button @click="showEdit = !showEdit" class="btn-ghost text-xs">
            {{ showEdit ? 'Cancel' : 'Edit' }}
          </button>
        </div>
        <form v-if="showEdit" @submit.prevent="handleUpdate" class="flex flex-col gap-3">
          <div class="flex gap-4">
            <div class="flex flex-col gap-1 flex-1">
              <label class="text-sm font-medium">Name</label>
              <input v-model="editForm.name" type="text" required class="input" />
            </div>
            <div class="flex flex-col gap-1 flex-1">
              <label class="text-sm font-medium">Email</label>
              <input v-model="editForm.email" type="email" required class="input" />
            </div>
          </div>
          <p v-if="updateError" class="text-sm text-red-500">{{ updateError }}</p>
          <div class="flex justify-end">
            <button type="submit" :disabled="updating" class="btn-primary">
              {{ updating ? 'Saving...' : 'Save Changes' }}
            </button>
          </div>
        </form>
      </div>

      <div v-if="!customer.deleted_at" class="bg-white rounded-xl border border-gray-200 p-5 flex flex-col gap-3">
        <h2 class="font-semibold">Delete Customer</h2>
        <p class="text-sm text-gray-500">Soft-deletes the customer. Existing payment records are preserved.</p>
        <p v-if="deleteError" class="text-sm text-red-500">{{ deleteError }}</p>
        <button @click="handleDelete" :disabled="deleting" class="btn-danger w-fit">
          {{ deleting ? 'Deleting...' : 'Delete Customer' }}
        </button>
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getCustomer, updateCustomer, deleteCustomer } from '../api/customers'
import { formatDate } from '../utils/format'
import { useAsyncAction } from '../composables/useAsyncAction'
import DetailCard from '../components/ui/DetailCard.vue'
import DetailRow from '../components/ui/DetailRow.vue'
import type { Customer } from '../api/types'

const route = useRoute()
const router = useRouter()
const uid = route.params.uid as string

const customer = ref<Customer | null>(null)
const showEdit = ref(false)
const editForm = reactive({ name: '', email: '' })

const { loading: updating, error: updateError, run: runUpdate } = useAsyncAction()
const { loading: deleting, error: deleteError, run: runDelete } = useAsyncAction()

async function handleUpdate() {
  await runUpdate(async () => {
    customer.value = await updateCustomer(uid, { name: editForm.name, email: editForm.email })
    showEdit.value = false
  })
}

async function handleDelete() {
  await runDelete(async () => {
    customer.value = await deleteCustomer(uid)
  })
}

onMounted(async () => {
  customer.value = await getCustomer(uid)
  editForm.name = customer.value.name
  editForm.email = customer.value.email
})
</script>
