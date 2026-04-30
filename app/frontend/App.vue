<template>
  <template v-if="merchantStore.isAuthenticated">
    <AppLayout @open-profile="showProfile = true">
      <RouterView />
    </AppLayout>
  </template>
  <template v-else>
    <LandingView @get-started="showOnboarding = true" />
  </template>

  <OnboardingModal v-model="showOnboarding" />
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import AppLayout from './components/layout/AppLayout.vue'
import LandingView from './views/LandingView.vue'
import OnboardingModal from './components/features/OnboardingModal.vue'
import { useMerchantStore } from './stores/merchant'

const merchantStore = useMerchantStore()
const showOnboarding = ref(false)
const showProfile = ref(false)

onMounted(async () => {
  if (merchantStore.isAuthenticated) {
    await merchantStore.fetchMe()
  }
})
</script>
