<script setup lang="ts">
import { computed, nextTick, ref, useTemplateRef, watch } from 'vue'
import { useMutation, useQueryClient } from '@tanstack/vue-query'

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'

import { ApiError, type ApiErrorDetail } from '~/lib/api/client'
import { updateInquiry, type UpdateInquiryInput } from '~/lib/api/inquiries'
import { createInquirySchema } from '~/lib/validation/inquiry'
import type { Inquiry } from '~/types/inquiry'
import type { Priority } from '~/types/priority'
import type { Status } from '~/types/status'

const props = defineProps<{
  inquiry: Inquiry
  statuses: Status[]
  priorities: Priority[]
}>()
const emit = defineEmits<{ close: [] }>()

// ========== Dialog open 状態 ==========
// 親が v-if でマウントするのでここでは true 起点。
// reka-ui Dialog が close 操作 (Esc / × / overlay) で false にしたら親に close 通知する。
const open = ref(true)
watch(open, (isOpen) => {
  if (!isOpen) emit('close')
})

// ========== inline edit 用ステート ==========
type EditableField = 'title' | 'description'

const editingField = ref<EditableField | null>(null)
const draft = ref<{ title: string; description: string }>({
  title: props.inquiry.title,
  description: props.inquiry.description ?? '',
})
const fieldErrors = ref<Record<string, string>>({})
const genericError = ref<string | null>(null)

// invalidate で props.inquiry が更新された場合、編集中でないフィールドだけ最新値に同期する。
// 編集中フィールドは draft を保持しないと、再 fetch で書き味が乱れる。
watch(
  () => props.inquiry,
  (next) => {
    if (editingField.value !== 'title') draft.value.title = next.title
    if (editingField.value !== 'description') draft.value.description = next.description ?? ''
  },
  { deep: true },
)

// ========== refs to focus ==========
const titleInput = useTemplateRef<HTMLInputElement>('titleInput')
const descriptionInput = useTemplateRef<HTMLTextAreaElement>('descriptionInput')

function enterEdit(field: EditableField) {
  if (mutation.isPending.value) return
  editingField.value = field
  // draft はマウント済み。focus を当てる。
  draft.value[field] = field === 'title' ? props.inquiry.title : (props.inquiry.description ?? '')
  fieldErrors.value[field] = ''
  nextTick(() => {
    if (field === 'title') titleInput.value?.focus()
    else descriptionInput.value?.focus()
  })
}

function cancelEdit() {
  if (editingField.value == null) return
  // 編集前の値（サーバ最新値）に戻して閲覧モードに戻る。PATCH は飛ばさない。
  draft.value.title = props.inquiry.title
  draft.value.description = props.inquiry.description ?? ''
  fieldErrors.value = {}
  editingField.value = null
}

function commit(field: EditableField) {
  const newValue = draft.value[field]
  const original = field === 'title' ? props.inquiry.title : (props.inquiry.description ?? '')

  // フィールド単位で zod 検証。createInquirySchema の各フィールド shape を再利用する。
  const result = createInquirySchema.shape[field].safeParse(newValue)
  if (!result.success) {
    fieldErrors.value[field] = result.error.errors[0]?.message ?? '入力に誤りがあります'
    return
  }
  fieldErrors.value[field] = ''

  if (newValue === original) {
    editingField.value = null
    return
  }

  mutation.mutate({ [field]: newValue } as UpdateInquiryInput)
}

// ========== select 系（change で即 PATCH） ==========
function changeStatus(event: Event) {
  const id = Number((event.target as HTMLSelectElement).value)
  if (!Number.isFinite(id) || id === props.inquiry.statusId) return
  mutation.mutate({ statusId: id })
}

function changePriority(event: Event) {
  const id = Number((event.target as HTMLSelectElement).value)
  if (!Number.isFinite(id) || id === props.inquiry.priorityId) return
  mutation.mutate({ priorityId: id })
}

// ========== mutation ==========
const queryClient = useQueryClient()
const mutation = useMutation({
  mutationFn: (input: UpdateInquiryInput) => updateInquiry(props.inquiry.id, input),
  onSuccess: () => {
    queryClient.invalidateQueries({ queryKey: ['inquiries'] })
    editingField.value = null
    fieldErrors.value = {}
    genericError.value = null
  },
  onError: (err) => {
    if (err instanceof ApiError && err.payload?.details?.length) {
      const details: ApiErrorDetail[] = err.payload.details
      const next: Record<string, string> = {}
      for (const d of details) {
        next[d.field] = humanizeReason(d.field, d.reason)
      }
      fieldErrors.value = next
      genericError.value = err.payload.message ?? '入力内容を確認してください'
      return
    }
    genericError.value = err instanceof Error ? err.message : '通信に失敗しました'
  },
})

function humanizeReason(field: string, reason: string): string {
  if (field === 'title') {
    if (reason === 'blank') return 'タイトルは必須です'
    if (reason === 'too_long') return '255 文字以内で入力してください'
  }
  if (reason === 'not_found') return '指定された項目が見つかりません'
  return reason
}

// ========== display helpers ==========
const taskCode = computed(() => `TASK-${props.inquiry.id}`)
const descriptionDisplay = computed(() => props.inquiry.description?.trim() || '本文なし')
</script>

<template>
  <Dialog v-model:open="open">
    <DialogContent class="sm:max-w-[640px]">
      <DialogHeader>
        <DialogTitle class="font-mono text-sm text-muted-foreground">
          {{ taskCode }}
        </DialogTitle>
        <DialogDescription class="sr-only">
          問い合わせを編集します。各フィールドをクリックして編集すると、フォーカスを外したときに自動保存されます。
        </DialogDescription>
      </DialogHeader>

      <div
        v-if="genericError"
        class="rounded-md border border-red-500/40 bg-red-50 px-3 py-2 text-sm text-red-700"
        role="alert"
      >
        {{ genericError }}
      </div>

      <div class="grid gap-4">
        <!-- タイトル -->
        <div class="grid gap-1.5">
          <label class="text-sm font-medium leading-none text-muted-foreground">
            タイトル
          </label>
          <input
            v-if="editingField === 'title'"
            ref="titleInput"
            v-model="draft.title"
            type="text"
            class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-1 text-lg font-semibold shadow-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
            :class="{ 'border-red-500 focus-visible:ring-red-500': fieldErrors.title }"
            @blur="commit('title')"
            @keydown.esc.prevent="cancelEdit"
            @keydown.enter.prevent="commit('title')"
          >
          <button
            v-else
            type="button"
            class="rounded-md border border-transparent px-3 py-1 text-left text-lg font-semibold text-foreground transition-colors hover:border-input hover:bg-muted/40"
            @click="enterEdit('title')"
          >
            {{ inquiry.title }}
          </button>
          <p v-if="fieldErrors.title" class="text-xs text-red-600">
            {{ fieldErrors.title }}
          </p>
        </div>

        <!-- 本文 -->
        <div class="grid gap-1.5">
          <label class="text-sm font-medium leading-none text-muted-foreground">
            本文
          </label>
          <textarea
            v-if="editingField === 'description'"
            ref="descriptionInput"
            v-model="draft.description"
            rows="6"
            class="flex w-full rounded-md border border-input bg-background px-3 py-2 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
            :class="{ 'border-red-500 focus-visible:ring-red-500': fieldErrors.description }"
            @blur="commit('description')"
            @keydown.esc.prevent="cancelEdit"
          />
          <button
            v-else
            type="button"
            class="min-h-[6rem] whitespace-pre-wrap rounded-md border border-transparent px-3 py-2 text-left text-sm text-foreground transition-colors hover:border-input hover:bg-muted/40"
            :class="{ 'text-muted-foreground italic': !inquiry.description?.trim() }"
            @click="enterEdit('description')"
          >
            {{ descriptionDisplay }}
          </button>
          <p v-if="fieldErrors.description" class="text-xs text-red-600">
            {{ fieldErrors.description }}
          </p>
        </div>

        <!-- ステータス・優先度 -->
        <div class="grid gap-4 sm:grid-cols-2">
          <div class="grid gap-1.5">
            <label class="text-sm font-medium leading-none text-muted-foreground">
              ステータス
            </label>
            <select
              :value="inquiry.statusId"
              :disabled="mutation.isPending.value"
              class="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:opacity-50"
              :class="{ 'border-red-500 focus-visible:ring-red-500': fieldErrors.statusId }"
              @change="changeStatus"
            >
              <option v-for="s in statuses" :key="s.id" :value="s.id">
                {{ s.name }}
              </option>
            </select>
            <p v-if="fieldErrors.statusId" class="text-xs text-red-600">
              {{ fieldErrors.statusId }}
            </p>
          </div>

          <div class="grid gap-1.5">
            <label class="text-sm font-medium leading-none text-muted-foreground">
              優先度
            </label>
            <select
              :value="inquiry.priorityId"
              :disabled="mutation.isPending.value"
              class="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:opacity-50"
              :class="{ 'border-red-500 focus-visible:ring-red-500': fieldErrors.priorityId }"
              @change="changePriority"
            >
              <option v-for="p in priorities" :key="p.id" :value="p.id">
                {{ p.name }}
              </option>
            </select>
            <p v-if="fieldErrors.priorityId" class="text-xs text-red-600">
              {{ fieldErrors.priorityId }}
            </p>
          </div>
        </div>

        <p
          v-if="mutation.isPending.value"
          class="text-xs text-muted-foreground"
          aria-live="polite"
        >
          保存中…
        </p>
      </div>
    </DialogContent>
  </Dialog>
</template>
