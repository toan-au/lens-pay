const ZERO_DECIMAL_CURRENCIES = ['JPY', 'KRW', 'VND', 'IDR', 'HUF', 'TWD', 'CLP', 'ISK']

export function formatAmount(amount: number, currency: string): string {
  const value = ZERO_DECIMAL_CURRENCIES.includes(currency.toUpperCase())
    ? amount
    : amount / 100
  return new Intl.NumberFormat('en-US', { style: 'currency', currency }).format(value)
}

export function formatDate(dateStr: string): string {
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(dateStr))
}

export function statusClass(status: string): string {
  const map: Record<string, string> = {
    pending: 'status-pending',
    authorized: 'status-authorized',
    processing: 'status-processing',
    succeeded: 'status-succeeded',
    declined: 'status-declined',
  }
  return `status-badge ${map[status] ?? 'status-pending'}`
}
