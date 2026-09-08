<template>
  <div
    v-if="modelValue"
    class="fixed inset-0 bg-black/40 flex items-center justify-center z-50"
    @keydown.esc="close"
  >
    <div
      ref="panel"
      role="dialog"
      aria-modal="true"
      :aria-labelledby="titleId"
      class="bg-white rounded-xl p-8 w-full max-w-md flex flex-col gap-4"
      @keydown.tab="trapTab"
    >
      <!-- Step 1: Registration form -->
      <template v-if="step === 1">
        <div class="flex items-center justify-between">
          <h2 :id="titleId" class="text-xl font-bold">Create your merchant account</h2>
          <button
            type="button"
            aria-label="Close"
            @click="close"
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
            <label :for="nameId" class="text-sm font-medium">Name</label>
            <input :id="nameId" v-model="form.name" type="text" required class="input" />
          </div>
          <div class="flex flex-col gap-1">
            <label :for="emailId" class="text-sm font-medium">Email</label>
            <input :id="emailId" v-model="form.email" type="email" required class="input" />
          </div>
          <div class="flex flex-col gap-1">
            <label :for="countryId" class="text-sm font-medium">Country</label>
            <select :id="countryId" v-model="form.country" required class="input">
              <option value="" disabled>Select a country</option>
              <option value="JP">Japan</option>
              <optgroup label="Other countries">
                <option value="AU">Australia</option>
                <option value="AT">Austria</option>
                <option value="BE">Belgium</option>
                <option value="BR">Brazil</option>
                <option value="CA">Canada</option>
                <option value="CN">China</option>
                <option value="DK">Denmark</option>
                <option value="FI">Finland</option>
                <option value="FR">France</option>
                <option value="DE">Germany</option>
                <option value="HK">Hong Kong</option>
                <option value="IN">India</option>
                <option value="ID">Indonesia</option>
                <option value="IE">Ireland</option>
                <option value="IT">Italy</option>
                <option value="MY">Malaysia</option>
                <option value="MX">Mexico</option>
                <option value="NL">Netherlands</option>
                <option value="NZ">New Zealand</option>
                <option value="NO">Norway</option>
                <option value="PH">Philippines</option>
                <option value="PL">Poland</option>
                <option value="PT">Portugal</option>
                <option value="SG">Singapore</option>
                <option value="ZA">South Africa</option>
                <option value="KR">South Korea</option>
                <option value="ES">Spain</option>
                <option value="SE">Sweden</option>
                <option value="CH">Switzerland</option>
                <option value="TW">Taiwan</option>
                <option value="TH">Thailand</option>
                <option value="GB">United Kingdom</option>
                <option value="US">United States</option>
                <option value="VN">Vietnam</option>
              </optgroup>
            </select>
          </div>
          <div class="flex flex-col gap-1">
            <label :for="currencyId" class="text-sm font-medium">Currency</label>
            <select :id="currencyId" v-model="form.currency" required class="input">
              <option value="JPY">JPY — Japanese Yen</option>
              <option value="USD">USD — US Dollar</option>
              <option value="EUR">EUR — Euro</option>
              <option value="GBP">GBP — British Pound</option>
              <option value="AUD">AUD — Australian Dollar</option>
              <option value="CAD">CAD — Canadian Dollar</option>
              <option value="NZD">NZD — New Zealand Dollar</option>
              <option value="SGD">SGD — Singapore Dollar</option>
              <option value="HKD">HKD — Hong Kong Dollar</option>
              <option value="KRW">KRW — South Korean Won</option>
              <option value="TWD">TWD — Taiwan Dollar</option>
              <option value="CNY">CNY — Chinese Yuan</option>
              <option value="THB">THB — Thai Baht</option>
              <option value="MYR">MYR — Malaysian Ringgit</option>
              <option value="IDR">IDR — Indonesian Rupiah</option>
              <option value="PHP">PHP — Philippine Peso</option>
              <option value="VND">VND — Vietnamese Dong</option>
              <option value="INR">INR — Indian Rupee</option>
              <option value="BRL">BRL — Brazilian Real</option>
              <option value="MXN">MXN — Mexican Peso</option>
              <option value="CHF">CHF — Swiss Franc</option>
              <option value="SEK">SEK — Swedish Krona</option>
              <option value="NOK">NOK — Norwegian Krone</option>
              <option value="DKK">DKK — Danish Krone</option>
              <option value="PLN">PLN — Polish Zloty</option>
              <option value="ZAR">ZAR — South African Rand</option>
            </select>
          </div>

          <p v-if="error" role="alert" class="text-sm text-red-500">{{ error }}</p>

          <button type="submit" :disabled="loading" class="btn-primary">
            {{ loading ? "Creating..." : "Create Account" }}
          </button>
        </form>

        <button
          type="button"
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
          <h2 :id="titleId" class="text-xl font-bold">Sign in</h2>
          <button
            type="button"
            aria-label="Close"
            @click="close"
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
            <label :for="signinKeyId" class="text-sm font-medium">API Key</label>
            <input
              :id="signinKeyId"
              v-model="signinKey"
              type="text"
              required
              placeholder="sk_..."
              class="input font-mono text-xs"
            />
          </div>
          <p v-if="error" role="alert" class="text-sm text-red-500">{{ error }}</p>
          <button type="submit" :disabled="loading" class="btn-primary">
            {{ loading ? "Signing in..." : "Sign in" }}
          </button>
        </form>

        <button
          type="button"
          @click="
            step = 1;
            error = '';
          "
          class="btn-ghost w-full"
        >
          <span aria-hidden="true">←</span> Back to registration
        </button>
      </template>

      <!-- Step 2: API key reveal -->
      <template v-else>
        <h2 :id="titleId" class="text-xl font-bold">Your API key</h2>
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
            type="button"
            @click="copy"
            class="btn-ghost whitespace-nowrap cursor-pointer"
          >
            {{ copied ? "Copied!" : "Copy" }}
          </button>
        </div>

        <button type="button" @click="handleClose" class="btn-primary cursor-pointer">
          Continue to dashboard
        </button>
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, watch, nextTick, useId } from "vue";
import { useMerchantStore } from "../../stores/merchant";

const props = defineProps<{ modelValue: boolean }>();
const emit = defineEmits<{ "update:modelValue": [value: boolean] }>();

const merchantStore = useMerchantStore();

const titleId = useId();
const nameId = useId();
const emailId = useId();
const countryId = useId();
const currencyId = useId();
const signinKeyId = useId();

const step = ref<1 | 2 | "signin">(1);
const apiKey = ref("");
const signinKey = ref("");
const copied = ref(false);
const loading = ref(false);
const error = ref("");
const panel = ref<HTMLElement | null>(null);
let opener: HTMLElement | null = null;

const form = reactive({
  name: "",
  email: "",
  country: "JP",
  currency: "JPY",
});

function focusables(): HTMLElement[] {
  if (!panel.value) return [];
  return Array.from(
    panel.value.querySelectorAll<HTMLElement>(
      'a[href],button:not([disabled]),input:not([disabled]),select:not([disabled]),textarea:not([disabled]),[tabindex]:not([tabindex="-1"])',
    ),
  );
}

function trapTab(e: KeyboardEvent) {
  const items = focusables();
  if (items.length === 0) return;
  const first = items[0];
  const last = items[items.length - 1];
  const active = document.activeElement;
  if (e.shiftKey && active === first) {
    e.preventDefault();
    last.focus();
  } else if (!e.shiftKey && active === last) {
    e.preventDefault();
    first.focus();
  }
}

function close() {
  emit("update:modelValue", false);
}

watch(
  () => props.modelValue,
  (open) => {
    if (open) {
      opener = document.activeElement as HTMLElement | null;
      nextTick(() => focusables()[0]?.focus());
    } else {
      step.value = 1;
      error.value = "";
      opener?.focus();
    }
  },
);

async function handleRegister() {
  loading.value = true;
  error.value = "";
  try {
    const result = await merchantStore.register(form);
    apiKey.value = result.api_key;
    step.value = 2;
    nextTick(() => focusables()[0]?.focus());
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
