<template>
  <div class="min-h-screen bg-gray-50">
    <nav class="bg-white border-b border-gray-200 px-8 h-14 flex items-center justify-between">
      <span class="font-bold text-lg tracking-tight">LensPay</span>
      <div class="flex items-center gap-2">
        <button
          @click="emit('openProfile')"
          class="text-sm border border-gray-200 rounded-md px-3 py-1.5 hover:bg-gray-50"
        >
          {{ merchantStore.merchant?.name ?? 'Account' }}
        </button>
        <button @click="logout" class="text-sm text-gray-400 hover:text-gray-700 px-2">
          Log out
        </button>
      </div>
    </nav>
    <main class="max-w-4xl mx-auto px-8 py-8">
      <slot />
    </main>
  </div>
</template>

<script setup lang="ts">
import { useMerchantStore } from '../../stores/merchant'

const merchantStore = useMerchantStore()
const emit = defineEmits<{ openProfile: [] }>()

function logout() {
  merchantStore.logout()
  window.location.href = '/'
}
</script>
