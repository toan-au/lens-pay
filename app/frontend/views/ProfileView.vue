<template>
  <div class="flex flex-col gap-6 max-w-xl">
    <h1 class="text-2xl font-bold">Profile</h1>

    <!-- Merchant details -->
    <div class="bg-white rounded-xl border border-gray-200 divide-y divide-gray-100">
      <div class="flex justify-between px-5 py-4">
        <span class="text-sm text-gray-500">Name</span>
        <span class="text-sm font-medium">{{ merchant?.name }}</span>
      </div>
      <div class="flex justify-between px-5 py-4">
        <span class="text-sm text-gray-500">Email</span>
        <span class="text-sm font-medium">{{ merchant?.email }}</span>
      </div>
      <div class="flex justify-between px-5 py-4">
        <span class="text-sm text-gray-500">Country</span>
        <span class="text-sm font-medium">{{ merchant?.country }}</span>
      </div>
      <div class="flex justify-between px-5 py-4">
        <span class="text-sm text-gray-500">Currency</span>
        <span class="text-sm font-medium">{{ merchant?.currency }}</span>
      </div>
      <div class="flex justify-between px-5 py-4">
        <span class="text-sm text-gray-500">Status</span>
        <span :class="statusClass(merchant?.status ?? '')">{{ merchant?.status }}</span>
      </div>
      <div class="flex justify-between px-5 py-4">
        <span class="text-sm text-gray-500">Merchant ID</span>
        <span class="text-xs font-mono text-gray-600">{{ merchant?.uid }}</span>
      </div>
    </div>

    <!-- API key -->
    <div class="flex flex-col gap-2">
      <h2 class="font-semibold text-sm">API Key</h2>
      <p class="text-xs text-red-500">Demo mode — not shown in production.</p>
      <ApiKeyDisplay v-if="merchantStore.apiKey" :api-key="merchantStore.apiKey" />
    </div>

    <!-- Webhook -->
    <div class="flex flex-col gap-2">
      <h2 class="font-semibold text-sm">Webhook</h2>
      <div class="bg-white rounded-xl border border-gray-200 divide-y divide-gray-100">
        <div class="flex justify-between px-5 py-4">
          <span class="text-sm text-gray-500">URL</span>
          <span class="text-xs font-mono text-gray-600">{{ merchant?.webhook_url ?? '—' }}</span>
        </div>
        <div class="flex flex-col gap-2 px-5 py-4">
          <span class="text-sm text-gray-500">Secret</span>
          <ApiKeyDisplay v-if="merchant?.webhook_secret" :api-key="merchant.webhook_secret" />
        </div>
      </div>
    </div>

    <button @click="logout" class="btn-danger w-fit cursor-pointer">Log out</button>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useMerchantStore } from '../stores/merchant'
import { statusClass } from '../utils/format'
import ApiKeyDisplay from '../components/ui/ApiKeyDisplay.vue'

const merchantStore = useMerchantStore()
const merchant = computed(() => merchantStore.merchant)

function logout() {
  merchantStore.logout()
  window.location.href = '/'
}
</script>
