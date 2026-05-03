<template>
  <div class="min-h-screen bg-white flex flex-col">

    <!-- Nav -->
    <nav class="px-8 h-14 flex items-center justify-between border-b border-gray-100">
      <span class="font-bold text-lg tracking-tight">LensPay</span>
      <button @click="emit('getStarted')" class="btn-primary">
        Get started
      </button>
    </nav>

    <!-- Hero -->
    <main class="flex-1 flex flex-col items-center justify-center px-8 text-center gap-6 py-24">
      <div class="flex flex-col gap-4 max-w-2xl">
        <h1 class="text-5xl font-bold tracking-tight text-gray-900 leading-tight">
          Payments infrastructure<br />for modern businesses.
        </h1>
        <p class="text-lg text-gray-500 max-w-xl mx-auto">
          Accept payments, manage refunds, and control your full payment lifecycle
          with a developer-first API — up and running in minutes.
        </p>
      </div>

      <div class="flex gap-3">
        <button @click="emit('getStarted')" class="btn-primary text-base px-6 py-2.5">
          Create your account →
        </button>
        <a href="https://github.com/toan-au/lens-pay" target="_blank" class="btn-ghost text-base px-6 py-2.5">
          View on GitHub
        </a>
      </div>
    </main>

    <!-- Features -->
    <section class="border-t border-gray-100 px-8 py-16">
      <div class="max-w-4xl mx-auto grid grid-cols-3 gap-8">
        <div v-for="feature in FEATURES" :key="feature.title" class="flex flex-col gap-2">
          <span class="text-2xl">{{ feature.icon }}</span>
          <h3 class="font-semibold text-gray-900">{{ feature.title }}</h3>
          <p class="text-sm text-gray-500">{{ feature.description }}</p>
        </div>
      </div>
    </section>

    <!-- Footer -->
    <footer class="border-t border-gray-100 px-8 py-6 text-center text-xs text-gray-400">
      LensPay — built as a portfolio project. Not a real payment processor.
    </footer>
  </div>
</template>

<script setup lang="ts">
const emit = defineEmits<{ getStarted: [] }>()

const FEATURES = [
  {
    icon: '⚡',
    title: 'Authorization & Capture',
    description: 'Authorize funds upfront and capture later — or partially. Full control over the payment lifecycle.',
  },
  {
    icon: '🔄',
    title: 'Refunds',
    description: 'Issue full or partial refunds against any captured payment. Track every refund in real time.',
  },
  {
    icon: '🔑',
    title: 'API key auth',
    description: 'Simple Bearer token authentication. Generate your key instantly — no OAuth flows, no dashboards to navigate.',
  },
]
</script>
