import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { createMerchant, getMe } from '../api/merchants'
import type { Merchant, MerchantCreateResponse } from '../api/types'

export const useMerchantStore = defineStore('merchant', () => {
  const merchant = ref<Merchant | null>(null)
  const apiKey = ref<string | null>(localStorage.getItem('api_key'))

  const isAuthenticated = computed(() => !!apiKey.value)

  function setApiKey(key: string) {
    apiKey.value = key
    localStorage.setItem('api_key', key)
  }

  function logout() {
    apiKey.value = null
    merchant.value = null
    localStorage.removeItem('api_key')
  }

  async function register(params: {
    name: string
    email: string
    country: string
    currency: string
  }): Promise<MerchantCreateResponse> {
    const result = await createMerchant(params)
    setApiKey(result.api_key)
    return result
  }

  async function fetchMe(): Promise<void> {
    merchant.value = await getMe()
  }

  return { merchant, apiKey, isAuthenticated, register, fetchMe, logout, setApiKey }
})
