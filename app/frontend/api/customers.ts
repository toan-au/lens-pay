import { api } from './client'
import type { Customer, CustomerListResponse } from './types'

export function listCustomers(params?: {
  cursor?: string
  limit?: number
}): Promise<CustomerListResponse> {
  const query = new URLSearchParams()
  if (params?.cursor) query.set('cursor', params.cursor)
  if (params?.limit) query.set('limit', String(params.limit))
  const qs = query.toString()
  return api.get<CustomerListResponse>(`/customers${qs ? `?${qs}` : ''}`)
}

export function getCustomer(uid: string): Promise<Customer> {
  return api.get<Customer>(`/customers/${uid}`)
}

export function createCustomer(params: {
  name: string
  email: string
  metadata?: Record<string, string>
}): Promise<Customer> {
  return api.post<Customer>('/customers', params)
}

export function updateCustomer(uid: string, params: {
  name?: string
  email?: string
  metadata?: Record<string, string>
}): Promise<Customer> {
  return api.patch<Customer>(`/customers/${uid}`, params)
}

export function deleteCustomer(uid: string): Promise<Customer> {
  return api.delete<Customer>(`/customers/${uid}`)
}
