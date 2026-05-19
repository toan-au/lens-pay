<template>
  <button type="submit" :disabled="loading" class="btn-primary">
    <template v-if="loading">{{ loadingLabel }}</template>
    <template v-else-if="amount != null">{{ label }} {{ formatAmount(amount, currency) }}</template>
    <template v-else>{{ label }}</template>
  </button>
</template>

<script setup lang="ts">
import { formatAmount } from '../../utils/format'

defineProps<{
  label: string
  loadingLabel: string
  amount: number | null | undefined
  currency: string
  loading: boolean
}>()
</script>
