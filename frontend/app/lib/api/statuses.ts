import type { Status } from '~/types/status'
import { apiFetch } from './client'

export async function fetchStatuses(): Promise<Status[]> {
  return apiFetch<Status[]>('/api/statuses')
}

// 作成リクエスト型。position はサーバ側で MAX(position)+1 を自動採番する。
export interface CreateStatusInput {
  name: string
  color: string
}

export async function createStatus(input: CreateStatusInput): Promise<Status> {
  return apiFetch<Status>('/api/statuses', {
    method: 'POST',
    body: JSON.stringify(input),
  })
}
