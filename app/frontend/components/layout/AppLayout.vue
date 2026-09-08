<template>
  <div class="min-h-screen bg-gray-50">
    <a
      href="#main-content"
      class="sr-only focus:not-sr-only focus:fixed focus:top-2 focus:left-2 focus:z-[100] focus:rounded-md focus:border focus:border-gray-300 focus:bg-white focus:px-3 focus:py-2 focus:text-sm"
    >
      Skip to main content
    </a>

    <header class="bg-white border-b border-gray-200 px-8 h-14 flex items-center justify-between">
      <div class="flex items-center gap-6">
        <span class="font-bold text-lg tracking-tight">LensPay</span>
        <nav aria-label="Primary" class="flex items-center gap-4 text-sm text-gray-500">
          <RouterLink to="/" class="hover:text-gray-900 transition-colors" active-class="text-gray-900 font-medium">Payments</RouterLink>
          <RouterLink to="/customers" class="hover:text-gray-900 transition-colors" active-class="text-gray-900 font-medium">Customers</RouterLink>
          <RouterLink to="/refunds" class="hover:text-gray-900 transition-colors" active-class="text-gray-900 font-medium">Refunds</RouterLink>
          <RouterLink to="/disputes" class="hover:text-gray-900 transition-colors" active-class="text-gray-900 font-medium">Disputes</RouterLink>
          <RouterLink to="/webhooks" class="hover:text-gray-900 transition-colors" active-class="text-gray-900 font-medium">Webhooks</RouterLink>
          <a href="/api-docs" target="_blank" rel="noopener" class="hover:text-gray-900 transition-colors">
            API Docs<span class="sr-only"> (opens in a new tab)</span>
          </a>
        </nav>
      </div>

      <div class="relative" @keydown.escape="closeMenu">
        <button
          ref="menuButton"
          @click="open = !open"
          :aria-expanded="open"
          aria-haspopup="true"
          aria-controls="account-menu"
          class="text-sm border border-gray-200 rounded-md px-3 py-1.5 hover:bg-gray-50 cursor-pointer"
        >
          {{ merchantStore.merchant?.name ?? 'Account' }}
        </button>

        <div
          v-if="open"
          id="account-menu"
          class="absolute right-0 mt-1 w-40 bg-white border border-gray-200 rounded-lg shadow-lg py-1 z-50"
        >
          <RouterLink
            to="/profile"
            @click="open = false"
            class="block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 cursor-pointer"
          >
            Profile
          </RouterLink>
          <button
            @click="logout"
            class="w-full text-left px-4 py-2 text-sm text-red-500 hover:bg-gray-50 cursor-pointer"
          >
            Log out
          </button>
        </div>
      </div>
    </header>

    <div v-if="open" class="fixed inset-0 z-40" aria-hidden="true" @click="open = false" />

    <main id="main-content" tabindex="-1" class="max-w-4xl mx-auto px-8 py-8 focus:outline-none">
      <slot />
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useMerchantStore } from '../../stores/merchant'

const merchantStore = useMerchantStore()
const open = ref(false)
const menuButton = ref<HTMLButtonElement | null>(null)

function closeMenu() {
  open.value = false
  menuButton.value?.focus()
}

function logout() {
  merchantStore.logout()
  window.location.href = '/'
}
</script>
