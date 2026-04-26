<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useMutation, useQuery, useQueryClient } from '@tanstack/vue-query'
import { useForm } from 'vee-validate'
import { toTypedSchema } from '@vee-validate/zod'
import { Plus } from 'lucide-vue-next'

import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog'

import { ApiError, type ApiErrorDetail } from '~/lib/api/client'
import { createInquiry, type CreateInquiryInput } from '~/lib/api/inquiries'
import { fetchPriorities } from '~/lib/api/priorities'
import { fetchStatuses } from '~/lib/api/statuses'
import { createInquirySchema } from '~/lib/validation/inquiry'
import type { Priority } from '~/types/priority'
import type { Status } from '~/types/status'

// statuses / priorities は親 (BoardListView) が既に取得済みのキャッシュを共有する。
// ここで useQuery を呼ぶことで vue-query が自動的に同じキーのキャッシュを返す。
const statusesQuery = useQuery<Status[]>({ queryKey: ['statuses'], queryFn: fetchStatuses })
const prioritiesQuery = useQuery<Priority[]>({ queryKey: ['priorities'], queryFn: fetchPriorities })

const open = ref(false)
const serverError = ref<string | null>(null)

const queryClient = useQueryClient()

// vee-validate + zod。submit 時に統合検証 + setFieldError でサーバ側エラーも反映する。
const {
  handleSubmit,
  resetForm,
  setErrors,
  errors,
  defineField,
  meta,
} = useForm({
  validationSchema: toTypedSchema(createInquirySchema),
  initialValues: {
    title: '',
    description: '',
    statusId: undefined as unknown as number,
    priorityId: undefined as unknown as number,
  },
})

// 入力中に即時バリデーションを走らせる（255 字超過 / 必須漏れをリアルタイムで提示）。
// validateOnBlur は false にする：reka-ui Dialog の close アニメーション中に
// input から focus が外れて blur 発火 → 空文字を validate → 一瞬エラー赤字が出る、を防ぐ。
// validateOnModelUpdate=true で入力中の検証は十分。
const fieldOptions = { validateOnModelUpdate: true, validateOnBlur: false } as const
const [title, titleAttrs] = defineField('title', fieldOptions)
const [description, descriptionAttrs] = defineField('description', fieldOptions)
const [statusId, statusIdAttrs] = defineField('statusId', fieldOptions)
const [priorityId, priorityIdAttrs] = defineField('priorityId', fieldOptions)

// 初期選択値: 先頭ステータス + 「低」優先度。
const lowPriorityId = computed(() => prioritiesQuery.data.value?.find(p => p.level === 3)?.id)
const firstStatusId = computed(() => statusesQuery.data.value?.[0]?.id)

// open=true になる瞬間にフォームを初期値にリセット。
// close 時にリセットすると vee-validate が空文字を再 validate してエラーが残るため、
// リセットは「次に開いた瞬間」だけに集約する。
function resetToInitial() {
  serverError.value = null
  resetForm({
    values: {
      title: '',
      description: '',
      statusId: firstStatusId.value as number,
      priorityId: lowPriorityId.value as number,
    },
  })
}

watch(open, (isOpen, wasOpen) => {
  if (isOpen && !wasOpen) resetToInitial()
})

const mutation = useMutation({
  mutationFn: (input: CreateInquiryInput) => createInquiry(input),
  onSuccess: () => {
    queryClient.invalidateQueries({ queryKey: ['inquiries'] })
    open.value = false
    serverError.value = null
  },
  onError: (err) => {
    if (err instanceof ApiError && err.payload?.details?.length) {
      // フィールド単位で setFieldError して赤線表示。汎用メッセージは serverError へ。
      const details: ApiErrorDetail[] = err.payload.details
      const fieldErrors: Record<string, string> = {}
      for (const d of details) {
        fieldErrors[d.field] = humanizeReason(d.field, d.reason)
      }
      setErrors(fieldErrors)
      serverError.value = err.payload.message ?? '入力内容を確認してください'
      return
    }
    serverError.value = err instanceof Error ? err.message : '通信に失敗しました'
  },
})

const onSubmit = handleSubmit((values) => {
  serverError.value = null
  mutation.mutate({
    statusId: values.statusId,
    priorityId: values.priorityId,
    title: values.title,
    description: values.description?.trim() ? values.description : undefined,
  })
})

function humanizeReason(field: string, reason: string): string {
  if (field === 'title') {
    if (reason === 'blank') return 'タイトルは必須です'
    if (reason === 'too_long') return '255 文字以内で入力してください'
    return `タイトルが正しくありません (${reason})`
  }
  if (field === 'statusId' && reason === 'required') return 'ステータスを選択してください'
  if (reason === 'not_found') return '指定された項目が見つかりません'
  return reason
}
</script>

<template>
  <Dialog v-model:open="open">
    <DialogTrigger as-child>
      <Button class="ml-auto">
        <Plus class="h-4 w-4" />
        新規
      </Button>
    </DialogTrigger>
    <DialogContent class="sm:max-w-[640px]">
      <DialogHeader>
        <DialogTitle>作品を追加</DialogTitle>
        <DialogDescription>
          作品名を入力し、視聴ステータスと気になり度を選択してください。
        </DialogDescription>
      </DialogHeader>

      <form class="grid gap-4" @submit.prevent="onSubmit">
        <div
          v-if="serverError"
          class="rounded-md border border-red-500/30 bg-red-950/40 px-3 py-2 text-sm text-red-400"
          role="alert"
        >
          {{ serverError }}
        </div>

        <!-- タイトル -->
        <div class="grid gap-1.5">
          <label for="inquiry-title" class="text-sm font-medium leading-none">
            作品名 <span class="text-red-600">*</span>
          </label>
          <input
            id="inquiry-title"
            v-model="title"
            v-bind="titleAttrs"
            type="text"
            class="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:opacity-50"
            :class="{ 'border-red-500 focus-visible:ring-red-500': errors.title }"
            placeholder="例：鬼滅の刃、君の名は。"
            autocomplete="off"
          >
          <p v-if="open && errors.title" class="text-xs text-red-600">
            {{ errors.title }}
          </p>
        </div>

        <!-- 本文 -->
        <div class="grid gap-1.5">
          <label for="inquiry-description" class="text-sm font-medium leading-none">
            メモ・感想
          </label>
          <textarea
            id="inquiry-description"
            v-model="description"
            v-bind="descriptionAttrs"
            rows="6"
            class="flex w-full rounded-md border border-input bg-background px-3 py-2 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:opacity-50"
            :class="{ 'border-red-500 focus-visible:ring-red-500': errors.description }"
            placeholder="感想・メモを入力（任意）"
          />
          <p v-if="open && errors.description" class="text-xs text-red-600">
            {{ errors.description }}
          </p>
        </div>

        <!-- ステータス・優先度 -->
        <div class="grid gap-4 sm:grid-cols-2">
          <div class="grid gap-1.5">
            <label for="inquiry-status" class="text-sm font-medium leading-none">
              視聴ステータス
            </label>
            <select
              id="inquiry-status"
              v-model.number="statusId"
              v-bind="statusIdAttrs"
              class="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:opacity-50"
              :class="{ 'border-red-500 focus-visible:ring-red-500': errors.statusId }"
            >
              <option v-for="s in statusesQuery.data.value ?? []" :key="s.id" :value="s.id">
                {{ s.name }}
              </option>
            </select>
            <p v-if="open && errors.statusId" class="text-xs text-red-600">
              {{ errors.statusId }}
            </p>
          </div>

          <div class="grid gap-1.5">
            <label for="inquiry-priority" class="text-sm font-medium leading-none">
              気になり度
            </label>
            <select
              id="inquiry-priority"
              v-model.number="priorityId"
              v-bind="priorityIdAttrs"
              class="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:opacity-50"
              :class="{ 'border-red-500 focus-visible:ring-red-500': errors.priorityId }"
            >
              <option v-for="p in prioritiesQuery.data.value ?? []" :key="p.id" :value="p.id">
                {{ p.name }}
              </option>
            </select>
            <p v-if="open && errors.priorityId" class="text-xs text-red-600">
              {{ errors.priorityId }}
            </p>
          </div>
        </div>

        <DialogFooter>
          <Button
            type="submit"
            :disabled="mutation.isPending.value || !meta.dirty"
          >
            {{ mutation.isPending.value ? '作成中…' : '作成' }}
          </Button>
        </DialogFooter>
      </form>
    </DialogContent>
  </Dialog>
</template>
