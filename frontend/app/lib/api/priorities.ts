import type { Priority } from '~/types/priority'
import { apiFetch } from './client'

export async function fetchPriorities(): Promise<Priority[]> {
  return apiFetch<Priority[]>('/api/priorities')
}
