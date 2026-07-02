<template>
  <div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
    <table class="w-full text-sm">
      <thead class="border-b border-gray-100 bg-gray-50">
        <tr><slot name="head" /></tr>
      </thead>
      <tbody>
        <tr v-if="loading && isEmpty">
          <td :colspan="cols" class="px-4 py-10 text-center text-gray-400">Loading...</td>
        </tr>
        <tr v-else-if="isEmpty">
          <td :colspan="cols" class="px-4 py-10 text-center text-gray-400">
            <slot name="empty">{{ emptyText }}</slot>
          </td>
        </tr>
        <slot v-else name="body" />
      </tbody>
    </table>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  loading: boolean
  isEmpty: boolean
  cols: number
  emptyText?: string
}>()
</script>
