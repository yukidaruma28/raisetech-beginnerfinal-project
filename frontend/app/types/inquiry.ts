// Rails の InquirySerializer が camelCase で返すレスポンスに対応する型。
// priority_id / category / assignee は次スライスで追加するため未対応。
export interface Inquiry {
  id: number
  statusId: number
  title: string
  description: string | null
  position: number
  createdAt: string
  updatedAt: string
}
