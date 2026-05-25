import { ref, onUnmounted } from 'vue'

export function usePolling(fn: () => Promise<boolean>, interval = 2000) {
  const active = ref(false)
  let timeout: ReturnType<typeof setTimeout> | null = null

  async function tick() {
    const keepGoing = await fn()
    if (keepGoing) {
      timeout = setTimeout(tick, interval)
    } else {
      active.value = false
      timeout = null
    }
  }

  function start() {
    if (!timeout) {
      active.value = true
      timeout = setTimeout(tick, interval)
    }
  }

  function stop() {
    active.value = false
    if (timeout) {
      clearTimeout(timeout)
      timeout = null
    }
  }

  onUnmounted(stop)

  return { active, start, stop }
}
