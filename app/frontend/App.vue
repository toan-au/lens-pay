<template>
  <template v-if="merchantStore.isAuthenticated">
    <AppLayout>
      <RouterView />
    </AppLayout>
  </template>
  <template v-else>
    <LandingView @get-started="showOnboarding = true" />
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

function handleUnauthorized() {
  merchantStore.logout()
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
