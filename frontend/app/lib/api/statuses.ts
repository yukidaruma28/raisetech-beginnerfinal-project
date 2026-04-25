import type { Status } from '~/types/status'
import { apiFetch } from './client'

export async function fetchStatuses(): Promise<Status[]> {
  return apiFetch<Status[]>('/api/statuses')
}
