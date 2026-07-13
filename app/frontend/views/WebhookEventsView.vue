<template>
  <div class="flex flex-col gap-6">
    <h1 class="text-2xl font-bold">Webhook Events</h1>

    <ResourceTable :loading="loading" :is-empty="events.length === 0" :cols="3" empty-text="No webhook events yet.">
      <template #head>
        <th class="text-left px-4 py-3 font-medium text-gray-500">Event</th>
        <th class="text-left px-4 py-3 font-medium text-gray-500">Payment</th>
        <th class="text-left px-4 py-3 font-medium text-gray-500">Date</th>
      </template>
      <template #body>
        <template v-for="event in events" :key="event.id">
          <tr
            class="border-t border-gray-100 hover:bg-gray-50 cursor-pointer transition-colors"
            @click="toggleRow(event.id)"
          >
            <td class="px-4 py-3 font-mono text-xs">{{ event.event_type }}</td>
            <td class="px-4 py-3 font-mono text-xs text-gray-500">{{ event.payload?.data?.id ?? '—' }}</td>
            <td class="px-4 py-3 text-xs text-gray-500">{{ formatDate(event.created_at) }}</td>
          </tr>
          <tr v-if="expandedId === event.id" class="border-t border-gray-100 bg-gray-50">
            <td colspan="3" class="px-4 py-4">
              <pre class="text-xs text-gray-600 overflow-x-auto">{{ JSON.stringify(event.payload, null, 2) }}</pre>
            </td>
          </tr>
        </template>
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
import { ref, onMounted } from 'vue'
import { listWebhookEvents } from '../api/webhook_events'
import { formatDate } from '../utils/format'
import ResourceTable from '../components/ui/ResourceTable.vue'
import type { WebhookEvent } from '../api/types'

const events = ref<WebhookEvent[]>([])
const nextCursor = ref<number | null>(null)
const loading = ref(false)
const expandedId = ref<number | null>(null)

function toggleRow(id: number) {
  expandedId.value = expandedId.value === id ? null : id
}

async function load(cursor?: number) {
  loading.value = true
  try {
    const { webhook_events, next_cursor } = await listWebhookEvents({ cursor })
    events.value = cursor ? [...events.value, ...webhook_events] : webhook_events
    nextCursor.value = next_cursor
  } finally {
    loading.value = false
  }
}

async function loadMore() {
  if (nextCursor.value) await load(nextCursor.value)
}

onMounted(() => load())
</script>
