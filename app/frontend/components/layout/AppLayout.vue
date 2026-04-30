<template>
  <div class="min-h-screen bg-gray-50">
    <nav class="bg-white border-b border-gray-200 px-8 h-14 flex items-center justify-between">
      <div class="flex items-center gap-6">
        <span class="font-bold text-lg tracking-tight">LensPay</span>
        <nav class="flex items-center gap-4 text-sm text-gray-500">
          <RouterLink to="/" class="hover:text-gray-900 transition-colors" active-class="text-gray-900 font-medium">Payments</RouterLink>
          <RouterLink to="/refunds" class="hover:text-gray-900 transition-colors" active-class="text-gray-900 font-medium">Refunds</RouterLink>
        </nav>
      </div>

      <div class="relative">
        <button
          @click="open = !open"
          class="text-sm border border-gray-200 rounded-md px-3 py-1.5 hover:bg-gray-50 cursor-pointer"
        >
          {{ merchantStore.merchant?.name ?? 'Account' }}
        </button>

        <div
          v-if="open"
          class="absolute right-0 mt-1 w-40 bg-white border border-gray-200 rounded-lg shadow-lg py-1 z-50"
        >
          <button
            @click="emit('openProfile')"
            class="w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 cursor-pointer"
          >
            Profile
          </button>
          <button
            @click="logout"
            class="w-full text-left px-4 py-2 text-sm text-red-500 hover:bg-gray-50 cursor-pointer"
          >
            Log out
          </button>
        </div>
      </div>
    </nav>

    <!-- Click outside to close -->
    <div v-if="open" class="fixed inset-0 z-40" @click="open = false" />

    <main class="max-w-4xl mx-auto px-8 py-8">
      <slot />
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useMerchantStore } from '../../stores/merchant'

const merchantStore = useMerchantStore()
const emit = defineEmits<{ openProfile: [] }>()
const open = ref(false)

function logout() {
  merchantStore.logout()
  window.location.href = '/'
}
</script>
