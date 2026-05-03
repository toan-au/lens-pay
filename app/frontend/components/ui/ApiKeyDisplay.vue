<template>
  <div class="flex items-center justify-between bg-gray-50 border border-gray-200 rounded-lg px-4 py-3 gap-4">
    <code class="text-xs text-gray-700 break-all">
      {{ revealed ? apiKey : masked }}
    </code>
    <button @click="handleAction" class="btn-ghost whitespace-nowrap cursor-pointer text-xs">
      {{ label }}
    </button>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'

const props = defineProps<{ apiKey: string }>()

const revealed = ref(false)
const copied = ref(false)

const masked = computed(() => {
  const underscoreIndex = props.apiKey.indexOf('_')
  const prefix = underscoreIndex !== -1 ? props.apiKey.slice(0, underscoreIndex + 1) : ''
  return `${prefix}${'*'.repeat(24)}`
})

const label = computed(() => {
  if (!revealed.value) return 'Show'
  return copied.value ? 'Copied!' : 'Copy'
})

function handleAction() {
  if (!revealed.value) {
    revealed.value = true
    return
  }
  navigator.clipboard.writeText(props.apiKey)
  copied.value = true
  setTimeout(() => (copied.value = false), 2000)
}
</script>
