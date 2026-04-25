import { z } from 'zod'

// 問い合わせ作成フォームのバリデーションスキーマ。
// サーバ側 `Inquiry` モデルと同じ制約を表現するが、
// statusId / priorityId はフォーム上 Select で扱うため select 候補と同じ number を期待する。
export const createInquirySchema = z.object({
  title: z
    .string({ required_error: 'タイトルは必須です' })
    .trim()
    .min(1, 'タイトルは必須です')
    .max(255, '255 文字以内で入力してください'),
  description: z.string().max(1000, '本文は 1,000 文字以内で入力してください').optional(),
  statusId: z
    .number({ required_error: 'ステータスを選択してください', invalid_type_error: 'ステータスを選択してください' })
    .int()
    .positive('ステータスを選択してください'),
  priorityId: z
    .number({ required_error: '優先度を選択してください', invalid_type_error: '優先度を選択してください' })
    .int()
    .positive('優先度を選択してください'),
})

export type CreateInquiryFormValues = z.infer<typeof createInquirySchema>
