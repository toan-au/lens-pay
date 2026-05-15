<template>
  <span :class="statusClass(status)">{{ status }}</span>
</template>

<script setup lang="ts">
import { statusClass } from '../../utils/format'
defineProps<{ status: string }>()
</script>
