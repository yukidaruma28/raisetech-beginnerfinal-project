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

export interface UpdateStatusInput {
  name?: string
  color?: string
}

export async function updateStatus(id: number, input: UpdateStatusInput): Promise<Status> {
  return apiFetch<Status>(`/api/statuses/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(input),
  })
}

export async function moveStatus(id: number, position: number): Promise<Status> {
  return apiFetch<Status>(`/api/statuses/${id}/move`, {
    method: 'PATCH',
    body: JSON.stringify({ position }),
  })
}

// DELETE /api/statuses/:id?move_to=<id>
// 所属 Inquiry が存在する場合は moveToId 必須（サーバ側で 409 を返す）。
// 0 件のときは moveToId を省略してそのまま削除できる。
export async function deleteStatus(id: number, moveToId?: number): Promise<void> {
  const qs = moveToId != null ? `?move_to=${moveToId}` : ''
  await apiFetch<undefined>(`/api/statuses/${id}${qs}`, { method: 'DELETE' })
}
