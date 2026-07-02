<template>
  <div class="flex justify-between px-5 py-4">
    <span class="text-sm text-gray-500" :class="labelClass">{{ label }}</span>
    <slot />
  </div>
</template>

<script setup lang="ts">
withDefaults(defineProps<{ label: string; labelClass?: string }>(), { labelClass: '' })
</script>
