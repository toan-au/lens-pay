<template>
  <div
    v-if="modelValue"
    class="fixed inset-0 bg-black/40 flex items-center justify-center z-50"
  >
    <div class="bg-white rounded-xl p-8 w-full max-w-md flex flex-col gap-4">
      <!-- Step 1: Registration form -->
      <template v-if="step === 1">
        <div class="flex items-center justify-between">
          <h2 class="text-xl font-bold">Create your merchant account</h2>
          <button
            @click="emit('update:modelValue', false)"
            class="text-gray-400 hover:text-gray-600 text-xl leading-none cursor-pointer"
          >
            &times;
          </button>
        </div>
        <p class="text-sm text-gray-500">
          Get an API key to start processing payments.
        </p>

        <form @submit.prevent="handleRegister" class="flex flex-col gap-3">
          <div class="flex flex-col gap-1">
            <label class="text-sm font-medium">Name</label>
            <input v-model="form.name" type="text" required class="input" />
          </div>
          <div class="flex flex-col gap-1">
            <label class="text-sm font-medium">Email</label>
            <input v-model="form.email" type="email" required class="input" />
          </div>
          <div class="flex flex-col gap-1">
            <label class="text-sm font-medium">Country</label>
            <input v-model="form.country" type="text" required class="input" />
          </div>
          <div class="flex flex-col gap-1">
            <label class="text-sm font-medium">Currency</label>
            <select v-model="form.currency" required class="input">
              <option value="JPY">JPY</option>
              <option value="USD">USD</option>
              <option value="EUR">EUR</option>
              <option value="AUD">AUD</option>
            </select>
          </div>

          <p v-if="error" class="text-sm text-red-500">{{ error }}</p>

          <button type="submit" :disabled="loading" class="btn-primary">
            {{ loading ? "Creating..." : "Create Account" }}
          </button>
        </form>

        <button
          @click="
            step = 'signin';
            error = '';
          "
          class="btn-ghost w-full"
        >
          Already have an API key?
        </button>
      </template>

      <!-- Step signin: API key input -->
      <template v-else-if="step === 'signin'">
        <div class="flex items-center justify-between">
          <h2 class="text-xl font-bold">Sign in</h2>
          <button
            @click="emit('update:modelValue', false)"
            class="text-gray-400 hover:text-gray-600 text-xl leading-none cursor-pointer"
          >
            &times;
          </button>
        </div>
        <p class="text-sm text-gray-500">
          Enter your API key to access your account.
        </p>

        <form @submit.prevent="handleSignIn" class="flex flex-col gap-3">
          <div class="flex flex-col gap-1">
            <label class="text-sm font-medium">API Key</label>
            <input
              v-model="signinKey"
              type="text"
              required
              placeholder="sk_..."
              class="input font-mono text-xs"
            />
          </div>
          <p v-if="error" class="text-sm text-red-500">{{ error }}</p>
          <button type="submit" :disabled="loading" class="btn-primary">
            {{ loading ? "Signing in..." : "Sign in" }}
          </button>
        </form>

        <button
          @click="
            step = 1;
            error = '';
          "
          class="btn-ghost w-full"
        >
          ← Back to registration
        </button>
      </template>

      <!-- Step 2: API key reveal -->
      <template v-else>
        <h2 class="text-xl font-bold">Your API key</h2>
        <p class="text-sm text-gray-500">
          Save this now — it won't be shown again.
        </p>
        <p class="text-sm text-red-500">
          Stored locally in your browser for this demo.
        </p>

        <div
          class="flex items-center justify-between bg-gray-50 border border-gray-200 rounded-lg px-4 py-3 gap-4"
        >
          <code class="text-xs break-all text-gray-700">{{ apiKey }}</code>
          <button
            @click="copy"
            class="btn-ghost whitespace-nowrap cursor-pointer"
          >
            {{ copied ? "Copied!" : "Copy" }}
          </button>
        </div>

        <button @click="handleClose" class="btn-primary cursor-pointer">
          Continue to dashboard
        </button>
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from "vue";
import { useMerchantStore } from "../../stores/merchant";

defineProps<{ modelValue: boolean }>();
const emit = defineEmits<{ "update:modelValue": [value: boolean] }>();

const merchantStore = useMerchantStore();

const step = ref<1 | 2 | "signin">(1);
const apiKey = ref("");
const signinKey = ref("");
const copied = ref(false);
const loading = ref(false);
const error = ref("");

const form = reactive({
  name: "",
  email: "",
  country: "",
  currency: "JPY",
});

async function handleRegister() {
  loading.value = true;
  error.value = "";
  try {
    const result = await merchantStore.register(form);
    apiKey.value = result.api_key;
    step.value = 2;
  } catch (e: any) {
    error.value = e.error ?? "Something went wrong";
  } finally {
    loading.value = false;
  }
}

async function handleSignIn() {
  loading.value = true;
  error.value = "";
  try {
    merchantStore.setApiKey(signinKey.value.trim());
    await merchantStore.fetchMe();
    emit("update:modelValue", false);
  } catch (e: any) {
    merchantStore.logout();
    error.value = "Invalid API key";
  } finally {
    loading.value = false;
  }
}

async function handleClose() {
  await merchantStore.fetchMe();
  emit("update:modelValue", false);
}

function copy() {
  navigator.clipboard.writeText(apiKey.value);
  copied.value = true;
  setTimeout(() => (copied.value = false), 2000);
}
</script>
