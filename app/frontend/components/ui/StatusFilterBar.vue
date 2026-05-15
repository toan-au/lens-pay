<template>
  <div class="flex gap-2 flex-wrap">
    <button
      v-for="tab in tabs"
      :key="tab.value"
      type="button"
      @click="$emit('update:modelValue', tab.value)"
      class="btn-ghost text-xs"
      :class="{ 'bg-gray-100 border-gray-400': modelValue === tab.value }"
    >
      {{ tab.label }}
    </button>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  tabs: { label: string; value: string }[]
  modelValue: string
}>()
defineEmits<{ 'update:modelValue': [value: string] }>()
</script>
