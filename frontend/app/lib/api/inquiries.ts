import type { Inquiry } from '~/types/inquiry'
import { apiFetch } from './client'

export async function fetchInquiries(): Promise<Inquiry[]> {
  return apiFetch<Inquiry[]>('/api/inquiries')
}

// 作成リクエスト型。priorityId は省略可（サーバ側で「低」に置換される）。
export interface CreateInquiryInput {
  statusId: number
  priorityId?: number
  title: string
  description?: string
}

export async function createInquiry(input: CreateInquiryInput): Promise<Inquiry> {
  return apiFetch<Inquiry>('/api/inquiries', {
    method: 'POST',
    body: JSON.stringify(input),
  })
}

// 部分更新リクエスト型。送信したフィールドだけがサーバ側で更新される。
export interface UpdateInquiryInput {
  title?: string
  description?: string
  statusId?: number
  priorityId?: number
}

export async function updateInquiry(id: number, input: UpdateInquiryInput): Promise<Inquiry> {
  return apiFetch<Inquiry>(`/api/inquiries/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(input),
  })
}
