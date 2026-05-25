<template>
  <div class="flex flex-col gap-4">
    <h2 class="font-semibold">Webhook Events</h2>

    <div v-if="events.length > 0" class="flex flex-col gap-3">
      <div v-for="event in events" :key="event.id" class="bg-white rounded-xl border border-gray-200">
        <button
          class="w-full px-5 py-4 flex items-center justify-between cursor-pointer"
          @click="toggle(event.id)"
        >
          <span class="text-sm font-mono font-medium">{{ event.event_type }}</span>
          <div class="flex items-center gap-3">
            <span class="text-xs text-gray-400">{{ formatDate(event.created_at) }}</span>
            <span class="text-gray-400 text-xs">{{ expanded.has(event.id) ? '▲' : '▼' }}</span>
          </div>
        </button>
        <div v-if="expanded.has(event.id)" class="px-5 pb-4">
          <pre class="text-xs bg-gray-50 rounded p-3 overflow-x-auto text-gray-600">{{ JSON.stringify(event.payload, null, 2) }}</pre>
        </div>
      </div>
    </div>

    <p v-else class="text-sm text-gray-400">No webhook events yet — fire a capture or refund to see events here.</p>
  </div>
</template>

<script setup lang="ts">
import { ref, onUnmounted } from 'vue'
import { listPaymentWebhookEvents } from '../../api/webhook_events'
import { formatDate } from '../../utils/format'
import type { WebhookEvent } from '../../api/types'

const props = defineProps<{ uid: string }>()

const events = ref<WebhookEvent[]>([])
const expanded = ref<Set<number>>(new Set())
let timeout: ReturnType<typeof setTimeout> | null = null

function toggle(id: number) {
  const next = new Set(expanded.value)
  next.has(id) ? next.delete(id) : next.add(id)
  expanded.value = next
}

async function poll() {
  const { webhook_events } = await listPaymentWebhookEvents(props.uid)
  events.value = webhook_events
  timeout = setTimeout(poll, 3000)
}

onUnmounted(() => { if (timeout) clearTimeout(timeout) })
poll()
</script>
