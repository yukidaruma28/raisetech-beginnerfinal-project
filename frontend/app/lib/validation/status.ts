import { z } from 'zod'

// Backend `Status::MAX_COUNT` と一致させる定数。
// サーバ側 422（base/max_count_exceeded）は最終防御線として残しつつ、
// UI 側は「上限到達で『+ 追加』ボタンを隠す」ためにこの値を参照する。
export const STATUS_MAX_COUNT = 10

export const HEX_COLOR_REGEX = /^#[0-9A-Fa-f]{6}$/

// プリセットカラー。シードと同系統 + オレンジ・ティールを足した 8 種。
// 任意色は HEX 入力欄で対応するため、ここはあくまで使い勝手向けの初期候補。
export const STATUS_PRESET_COLORS = [
  '#95A5A6', // grey   (Backlog 系)
  '#3498DB', // blue   (Todo 系)
  '#F1C40F', // yellow (In Progress 系)
  '#9B59B6', // purple (In Review 系)
  '#2ECC71', // green  (Done 系)
  '#E74C3C', // red    (Canceled 系)
  '#E67E22', // orange
  '#1ABC9C', // teal
] as const

// ステータス作成フォームのバリデーションスキーマ。
// name の上限はサーバ側 statuses.name の VARCHAR(100) と一致させる
// （Inquiry の 255 とは別物。揃えると DB CHECK で弾かれる）。
export const createStatusSchema = z.object({
  name: z
    .string({ required_error: 'ステータス名は必須です' })
    .trim()
    .min(1, 'ステータス名は必須です')
    .max(100, '100 文字以内で入力してください'),
  color: z
    .string({ required_error: '色は必須です' })
    .regex(HEX_COLOR_REGEX, '有効な HEX カラー（例: #3498DB）を入力してください'),
})

export type CreateStatusFormValues = z.infer<typeof createStatusSchema>
