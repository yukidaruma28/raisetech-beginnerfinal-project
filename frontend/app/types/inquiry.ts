// Rails の InquirySerializer が camelCase で返すレスポンスに対応する型。
// category / assignee は MVP スコープ外（docs/tech-stack.md 参照）。
// priority は必須（3 段階 + デフォルト「低」）。
export interface Inquiry {
  id: number
  statusId: number
  priorityId: number
  title: string
  description: string | null
  position: number
  createdAt: string
  updatedAt: string
}
