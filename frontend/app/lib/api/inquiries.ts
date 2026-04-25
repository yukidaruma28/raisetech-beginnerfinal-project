import type { Inquiry } from '~/types/inquiry'
import { apiFetch } from './client'

export async function fetchInquiries(): Promise<Inquiry[]> {
  return apiFetch<Inquiry[]>('/api/inquiries')
}
