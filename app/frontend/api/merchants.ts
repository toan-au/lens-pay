import { api } from './client'
import type { Merchant, MerchantCreateResponse } from './types'

export function createMerchant(params: {
  name: string
  email: string
  country: string
  currency: string
}): Promise<MerchantCreateResponse> {
  return api.post<MerchantCreateResponse>('/merchants', params)
}

export function getMe(): Promise<Merchant> {
  return api.get<Merchant>('/merchants/me')
}
