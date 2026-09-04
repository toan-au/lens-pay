import { describe, it, expect } from 'vitest'
import {
  toMinorUnits,
  fromMinorUnits,
  formatAmount,
  formatDate,
  statusClass,
} from './format'

describe('toMinorUnits', () => {
  it('multiplies by 100 and rounds for decimal currencies', () => {
    expect(toMinorUnits(10, 'USD')).toBe(1000)
    expect(toMinorUnits(10.005, 'USD')).toBe(1001)
    expect(toMinorUnits(-4.2, 'USD')).toBe(-420)
  })

  it('rounds to whole units for zero-decimal currencies', () => {
    expect(toMinorUnits(1000, 'JPY')).toBe(1000)
    expect(toMinorUnits(1000.4, 'JPY')).toBe(1000)
  })

  it('is case-insensitive about the currency code', () => {
    expect(toMinorUnits(1000, 'jpy')).toBe(1000)
    expect(toMinorUnits(10, 'usd')).toBe(1000)
  })
})

describe('fromMinorUnits', () => {
  it('divides by 100 for decimal currencies', () => {
    expect(fromMinorUnits(1000, 'USD')).toBe(10)
    expect(fromMinorUnits(1, 'USD')).toBe(0.01)
  })

  it('passes zero-decimal currencies through untouched', () => {
    expect(fromMinorUnits(1000, 'JPY')).toBe(1000)
    expect(fromMinorUnits(1000, 'jpy')).toBe(1000)
  })
})

describe('formatAmount', () => {
  // Inline snapshots self-record the exact ICU string for the pinned Node build
  // (.nvmrc), then lock it. Never hand-write these — modern ICU inserts a U+202F
  // narrow no-break space that is invisible in review.
  it('formats a decimal currency from minor units', () => {
    expect(formatAmount(1000, 'USD')).toMatchInlineSnapshot(`"$10.00"`)
  })

  it('formats a zero-decimal currency without dividing', () => {
    expect(formatAmount(1000, 'JPY')).toMatchInlineSnapshot(`"¥1,000"`)
  })
})

describe('formatDate', () => {
  // TZ pinned to UTC by vitest.config.ts (test.env.TZ) + test/setup.ts guard.
  it('formats an ISO timestamp in UTC', () => {
    expect(formatDate('2024-01-15T09:05:00Z')).toMatchInlineSnapshot(`"Jan 15, 2024, 09:05 AM"`)
  })
})

describe('statusClass', () => {
  it.each([
    ['pending', 'status-badge status-pending'],
    ['succeeded', 'status-badge status-succeeded'],
    ['active', 'status-badge status-succeeded'],
    ['won', 'status-badge status-succeeded'],
    ['open', 'status-badge status-declined'],
    ['lost', 'status-badge status-declined'],
    ['merchant_responded', 'status-badge status-processing'],
    ['failed', 'status-badge status-failed'],
  ])('maps %s -> %s', (input, expected) => {
    expect(statusClass(input)).toBe(expected)
  })

  it('falls back to the pending class for an unknown status', () => {
    expect(statusClass('nonsense')).toBe('status-badge status-pending')
    expect(statusClass('')).toBe('status-badge status-pending')
  })
})
