import { describe, it, expect } from 'vitest'
import { useAsyncAction } from './useAsyncAction'

describe('useAsyncAction', () => {
  it('toggles loading around a successful run and leaves error empty', async () => {
    const { loading, error, run } = useAsyncAction()
    expect(loading.value).toBe(false)

    let loadingDuringRun = false
    await run(async () => {
      loadingDuringRun = loading.value // captured mid-flight
    })

    expect(loadingDuringRun).toBe(true)
    expect(loading.value).toBe(false)
    expect(error.value).toBe('')
  })

  it('joins an { errors: [...] } payload into a comma-separated string', async () => {
    const { error, run } = useAsyncAction()

    await run(async () => {
      throw { errors: ['Name required', 'Email is invalid'] }
    })

    expect(error.value).toBe('Name required, Email is invalid')
  })

  it('falls back to { error } when there is no errors array', async () => {
    const { error, run } = useAsyncAction()

    await run(async () => {
      throw { error: 'Payment not found' }
    })

    expect(error.value).toBe('Payment not found')
  })

  it('uses a generic message for a throw with neither errors nor error', async () => {
    const { error, run } = useAsyncAction()

    await run(async () => {
      throw new Error('boom')
    })

    expect(error.value).toBe('Something went wrong')
  })

  it('still sets loading back to false when the action throws', async () => {
    const { loading, run } = useAsyncAction()

    await run(async () => {
      throw { error: 'nope' }
    })

    expect(loading.value).toBe(false)
  })

  it('clears a previous error at the start of the next run', async () => {
    const { error, run } = useAsyncAction()

    await run(async () => {
      throw { error: 'first failure' }
    })
    expect(error.value).toBe('first failure')

    await run(async () => {
      // this one succeeds
    })
    expect(error.value).toBe('')
  })
})
