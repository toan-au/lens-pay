<template>
  <div class="min-h-screen bg-white flex flex-col">

    <!-- Nav -->
    <nav class="px-8 h-14 flex items-center justify-between border-b border-gray-100 sticky top-0 bg-white z-10">
      <span class="font-bold text-lg tracking-tight">LensPay</span>
      <div class="flex items-center gap-3">
        <a href="https://github.com/toan-au/lens-pay" target="_blank" class="text-sm text-gray-500 hover:text-gray-800">GitHub</a>
        <a href="/api-docs" target="_blank" class="text-sm text-gray-500 hover:text-gray-800">API Docs</a>
        <button @click="emit('getStarted')" class="btn-primary text-sm">Get started</button>
      </div>
    </nav>

    <!-- Hero -->
    <section class="flex flex-col items-center justify-center px-8 text-center gap-8 py-28 bg-gradient-to-b from-white to-gray-50">
      <div class="flex flex-col gap-5 max-w-2xl">
        <div class="inline-flex items-center gap-2 bg-indigo-50 text-indigo-700 text-xs font-medium px-3 py-1.5 rounded-full mx-auto">
          <span class="w-1.5 h-1.5 rounded-full bg-indigo-500"></span>
          Production-ready payment patterns
        </div>
        <h1 class="text-5xl font-bold tracking-tight text-gray-900 leading-tight">
          Payment processing API<br />built for developers.
        </h1>
        <p class="text-lg text-gray-500 max-w-xl mx-auto leading-relaxed">
          Authorization, capture, refunds, webhooks, and customer management —
          all through a clean REST API with idempotency, cursor pagination, and HMAC-signed events.
        </p>
      </div>

      <div class="flex gap-3 flex-wrap justify-center">
        <button @click="emit('tryDemo')" :disabled="demoLoading" class="btn-primary text-base px-6 py-2.5">
          {{ demoLoading ? 'Setting up...' : 'Try the demo →' }}
        </button>
        <button @click="emit('getStarted')" class="btn-ghost text-base px-6 py-2.5">
          Create your account
        </button>
      </div>
      <p class="text-xs text-gray-400">Demo accounts are ephemeral — pre-seeded with data and reset daily.</p>
    </section>

    <!-- Payment lifecycle -->
    <section class="border-t border-gray-100 px-8 py-20 bg-white">
      <div class="max-w-4xl mx-auto flex flex-col gap-10">
        <div class="text-center flex flex-col gap-2">
          <h2 class="text-2xl font-bold text-gray-900">Full payment lifecycle</h2>
          <p class="text-gray-500 text-sm">Every state transition is modelled, validated, and emits a webhook event.</p>
        </div>

        <div class="flex items-center justify-center gap-1 flex-wrap">
          <div v-for="(step, i) in LIFECYCLE" :key="step.label" class="flex items-center gap-1">
            <div class="flex flex-col items-center gap-1.5">
              <div :class="['text-xs font-mono px-3 py-1.5 rounded-lg border font-medium', step.class]">
                {{ step.label }}
              </div>
              <span class="text-xs text-gray-400">{{ step.event }}</span>
            </div>
            <span v-if="i < LIFECYCLE.length - 1" class="text-gray-300 text-sm mb-4">→</span>
          </div>
        </div>

        <div class="grid grid-cols-3 gap-4 text-sm">
          <div class="bg-amber-50 border border-amber-100 rounded-xl p-4 flex flex-col gap-1">
            <span class="font-semibold text-amber-800">Declined</span>
            <span class="text-amber-700 text-xs">Card network rejects the charge. Fires <code class="font-mono">payment.failed</code>.</span>
          </div>
          <div class="bg-red-50 border border-red-100 rounded-xl p-4 flex flex-col gap-1">
            <span class="font-semibold text-red-800">Cancelled</span>
            <span class="text-red-700 text-xs">Merchant voids the payment before capture. Fires <code class="font-mono">payment.cancelled</code>.</span>
          </div>
          <div class="bg-gray-50 border border-gray-100 rounded-xl p-4 flex flex-col gap-1">
            <span class="font-semibold text-gray-700">Expired</span>
            <span class="text-gray-500 text-xs">Pending payments expire after 3 days. Fires <code class="font-mono">payment.expired</code>.</span>
          </div>
        </div>
      </div>
    </section>

    <!-- Features -->
    <section class="border-t border-gray-100 px-8 py-20 bg-gray-50">
      <div class="max-w-4xl mx-auto flex flex-col gap-10">
        <div class="text-center flex flex-col gap-2">
          <h2 class="text-2xl font-bold text-gray-900">Everything you'd expect from a payment gateway</h2>
        </div>
        <div class="grid grid-cols-2 gap-5 sm:grid-cols-3">
          <div v-for="feature in FEATURES" :key="feature.title" class="bg-white rounded-xl border border-gray-200 p-5 flex flex-col gap-2">
            <span class="text-xl">{{ feature.icon }}</span>
            <h3 class="font-semibold text-gray-900 text-sm">{{ feature.title }}</h3>
            <p class="text-xs text-gray-500 leading-relaxed">{{ feature.description }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- API preview -->
    <section class="border-t border-gray-100 px-8 py-20 bg-white">
      <div class="max-w-4xl mx-auto flex flex-col gap-10 lg:flex-row lg:items-start lg:gap-16">
        <div class="flex flex-col gap-4 lg:w-1/2">
          <h2 class="text-2xl font-bold text-gray-900">Clean, predictable API</h2>
          <p class="text-gray-500 text-sm leading-relaxed">
            All endpoints follow REST conventions. Authenticate with a Bearer token,
            pass an idempotency key to safely retry, and get consistent JSON back.
          </p>
          <ul class="text-sm text-gray-600 flex flex-col gap-2">
            <li class="flex items-center gap-2"><span class="text-green-500">✓</span> Idempotency keys on payments and refunds</li>
            <li class="flex items-center gap-2"><span class="text-green-500">✓</span> Cursor-based pagination on all list endpoints</li>
            <li class="flex items-center gap-2"><span class="text-green-500">✓</span> Rate limiting per merchant and per IP</li>
            <li class="flex items-center gap-2"><span class="text-green-500">✓</span> <a href="/api-docs" target="_blank" class="text-indigo-600 hover:underline">Interactive OpenAPI documentation</a></li>
          </ul>
        </div>
        <div class="lg:w-1/2 bg-gray-900 rounded-xl p-5 text-xs font-mono text-gray-300 leading-relaxed overflow-x-auto">
          <div class="text-gray-500 mb-2"># Create a payment</div>
          <div><span class="text-indigo-400">POST</span> /api/v1/payments</div>
          <div class="text-gray-500 mt-1">Authorization: Bearer sk_...</div>
          <div class="mt-3 text-gray-400">{</div>
          <div class="ml-4"><span class="text-green-400">"amount"</span>: <span class="text-amber-400">1500</span>,</div>
          <div class="ml-4"><span class="text-green-400">"currency"</span>: <span class="text-orange-400">"JPY"</span>,</div>
          <div class="ml-4"><span class="text-green-400">"idempotency_key"</span>: <span class="text-orange-400">"order_42"</span></div>
          <div class="text-gray-400">}</div>
          <div class="mt-4 border-t border-gray-700 pt-4 text-gray-500"># Response</div>
          <div class="text-gray-400">{</div>
          <div class="ml-4"><span class="text-green-400">"uid"</span>: <span class="text-orange-400">"pay_..."</span>,</div>
          <div class="ml-4"><span class="text-green-400">"status"</span>: <span class="text-orange-400">"pending"</span>,</div>
          <div class="ml-4"><span class="text-green-400">"amount"</span>: <span class="text-amber-400">1500</span></div>
          <div class="text-gray-400">}</div>
        </div>
      </div>
    </section>

    <!-- Tech stack -->
    <section class="border-t border-gray-100 px-8 py-16 bg-gray-50">
      <div class="max-w-4xl mx-auto flex flex-col items-center gap-4 text-center">
        <h2 class="text-lg font-bold text-gray-900">Built with</h2>
        <div class="flex flex-wrap gap-3 justify-center">
          <span v-for="tech in TECH_STACK" :key="tech" class="bg-white border border-gray-200 rounded-lg px-4 py-2 text-sm text-gray-600 font-medium">
            {{ tech }}
          </span>
        </div>
      </div>
    </section>

    <!-- Footer -->
    <footer class="border-t border-gray-100 px-8 py-8 text-center text-xs text-gray-400 flex flex-col gap-2">
      <div class="flex justify-center gap-6">
        <a href="https://github.com/toan-au/lens-pay" target="_blank" class="hover:text-gray-600">GitHub</a>
        <a href="/api-docs" target="_blank" class="hover:text-gray-600">API Docs</a>
        <button @click="emit('tryDemo')" class="hover:text-gray-600">Try the demo</button>
      </div>
      <p>LensPay — built as a portfolio project. Not a real payment processor.</p>
    </footer>
  </div>
</template>

<script setup lang="ts">
const emit = defineEmits<{ getStarted: []; tryDemo: [] }>()

defineProps<{ demoLoading?: boolean }>()

const LIFECYCLE = [
  { label: 'pending',    event: 'payment.created',    class: 'bg-gray-100 text-gray-600 border-gray-200' },
  { label: 'authorized', event: 'payment.authorized', class: 'bg-blue-50 text-blue-700 border-blue-200' },
  { label: 'processing', event: 'payment.captured',   class: 'bg-indigo-50 text-indigo-700 border-indigo-200' },
  { label: 'succeeded',  event: 'payment.refunded',   class: 'bg-green-50 text-green-700 border-green-200' },
]

const FEATURES = [
  {
    icon: '⚡',
    title: 'Authorization & Capture',
    description: 'Two-step payment flow. Authorize funds upfront, capture the exact amount later — or partially capture and release the remainder.',
  },
  {
    icon: '🔄',
    title: 'Full & Partial Refunds',
    description: 'Refund any amount up to the captured total. Multiple partial refunds supported. Each refund is idempotent and tracked independently.',
  },
  {
    icon: '🪝',
    title: 'Webhook Delivery',
    description: 'HMAC-SHA256 signed events delivered to your endpoint on every state change. Automatic retries with exponential backoff on failure.',
  },
  {
    icon: '👥',
    title: 'Customer Management',
    description: 'Store customers and attach them to payments. Customer name and email are snapshotted on each payment for a reliable audit trail.',
  },
  {
    icon: '🔑',
    title: 'API Key Auth',
    description: 'Simple Bearer token authentication. Keys are hashed at rest — never stored in plaintext. Rate limited per merchant and per IP.',
  },
  {
    icon: '🔁',
    title: 'Idempotency',
    description: 'Submit the same request multiple times safely. Duplicate payments and refunds are detected and the original result returned.',
  },
  {
    icon: '⏱️',
    title: 'Payment Expiry',
    description: 'Pending payments automatically expire after 3 days, releasing reserved funds and firing a webhook to notify your backend.',
  },
  {
    icon: '📄',
    title: 'OpenAPI Docs',
    description: 'Every endpoint is documented and testable in the browser. Generated from the integration test suite — always in sync with the code.',
  },
]

const TECH_STACK = [
  'Ruby on Rails 8.1',
  'PostgreSQL',
  'Solid Queue',
  'Vue 3',
  'Pinia',
  'TypeScript',
  'Tailwind CSS',
  'RSpec',
]
</script>
