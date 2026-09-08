<template>
  <div class="flex gap-2 flex-wrap" role="group" :aria-label="label">
    <button
      v-for="tab in tabs"
      :key="tab.value"
      type="button"
      :aria-pressed="modelValue === tab.value"
      @click="$emit('update:modelValue', tab.value)"
      class="btn-ghost text-xs"
      :class="{ 'bg-gray-100 border-gray-400': modelValue === tab.value }"
    >
      {{ tab.label }}
    </button>
  </div>
</template>

<script setup lang="ts">
withDefaults(
  defineProps<{
    tabs: { label: string; value: string }[]
    modelValue: string
    label?: string
  }>(),
  { label: 'Filter by status' },
)
defineEmits<{ 'update:modelValue': [value: string] }>()
</script>
