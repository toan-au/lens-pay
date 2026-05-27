<template>
  <template v-if="merchantStore.isAuthenticated">
    <AppLayout>
      <RouterView />
    </AppLayout>
  </template>
  <template v-else>
    <LandingView :demo-loading="demoLoading" @get-started="showOnboarding = true" @try-demo="handleTryDemo" />
  </template>

  <OnboardingModal v-model="showOnboarding" />
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import AppLayout from './components/layout/AppLayout.vue'
import LandingView from './views/LandingView.vue'
import OnboardingModal from './components/features/OnboardingModal.vue'
import { useMerchantStore } from './stores/merchant'

const merchantStore = useMerchantStore()
const showOnboarding = ref(false)
const demoLoading = ref(false)

function handleUnauthorized() {
  merchantStore.logout()
}

async function handleTryDemo() {
  demoLoading.value = true
  try {
    await merchantStore.loginAsDemo()
    await merchantStore.fetchMe()
  } finally {
    demoLoading.value = false
  }
}

onMounted(async () => {
  window.addEventListener('auth:unauthorized', handleUnauthorized)
  if (merchantStore.isAuthenticated) {
    try {
      await merchantStore.fetchMe()
    } catch {
      // fetchMe failing means the stored key is invalid — logout clears it
      merchantStore.logout()
    }
  }
})

onUnmounted(() => {
  window.removeEventListener('auth:unauthorized', handleUnauthorized)
})
</script>
