import { ref } from 'vue'

export function useAsyncAction() {
  const loading = ref(false)
  const error = ref('')

  async function run(fn: () => Promise<void>) {
    loading.value = true
    error.value = ''
    try {
      await fn()
    } catch (e: any) {
      error.value = e.errors?.join(', ') ?? e.error ?? 'Something went wrong'
    } finally {
      loading.value = false
    }
  }

  return { loading, error, run }
}
