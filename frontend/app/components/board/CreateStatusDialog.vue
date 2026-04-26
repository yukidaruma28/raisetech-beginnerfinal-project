<script setup lang="ts">
import { ref, watch } from 'vue'
import { useMutation, useQueryClient } from '@tanstack/vue-query'
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
import { createStatus, type CreateStatusInput } from '~/lib/api/statuses'
import {
  STATUS_PRESET_COLORS,
  createStatusSchema,
} from '~/lib/validation/status'

const open = ref(false)
const serverError = ref<string | null>(null)

const queryClient = useQueryClient()

// vee-validate + zod。ノウハウは UC-02 (CreateInquiryDialog) と同じ:
//   - validateOnBlur: false で reka-ui Dialog の close アニメ中の blur 起因
//     エラーちらつきを抑える。
//   - エラー文言は v-if="open && errors.xxx" でガードして閉じた瞬間に消す。
//   - resetForm は open 立ち上がり時のみ実行する（close 時にやると再 validate される）。
const {
  handleSubmit,
  resetForm,
  setErrors,
  errors,
  defineField,
  meta,
} = useForm({
  validationSchema: toTypedSchema(createStatusSchema),
  initialValues: {
    name: '',
    color: STATUS_PRESET_COLORS[1], // 初期は Todo 系の青
  },
})

const fieldOptions = { validateOnModelUpdate: true, validateOnBlur: false } as const
const [name, nameAttrs] = defineField('name', fieldOptions)
const [color, colorAttrs] = defineField('color', fieldOptions)

function resetToInitial() {
  serverError.value = null
  resetForm({
    values: {
      name: '',
      color: STATUS_PRESET_COLORS[1],
    },
  })
}

watch(open, (isOpen, wasOpen) => {
  if (isOpen && !wasOpen) resetToInitial()
})

const mutation = useMutation({
  mutationFn: (input: CreateStatusInput) => createStatus(input),
  onSuccess: () => {
    queryClient.invalidateQueries({ queryKey: ['statuses'] })
    open.value = false
    serverError.value = null
  },
  onError: (err) => {
    if (err instanceof ApiError && err.payload?.details?.length) {
      const details: ApiErrorDetail[] = err.payload.details
      const fieldErrors: Record<string, string> = {}
      let baseMessage: string | null = null
      for (const d of details) {
        if (d.field === 'base') {
          // 上限超過などの「フィールドに紐づかない」エラーは serverError に集約。
          baseMessage = humanizeReason(d.field, d.reason)
        } else {
          fieldErrors[d.field] = humanizeReason(d.field, d.reason)
        }
      }
      if (Object.keys(fieldErrors).length > 0) setErrors(fieldErrors)
      serverError.value = baseMessage ?? err.payload.message ?? '入力内容を確認してください'
      return
    }
    serverError.value = err instanceof Error ? err.message : '通信に失敗しました'
  },
})

const onSubmit = handleSubmit((values) => {
  serverError.value = null
  mutation.mutate({
    name: values.name.trim(),
    color: values.color,
  })
})

function humanizeReason(field: string, reason: string): string {
  if (field === 'name') {
    if (reason === 'blank') return 'ステータス名は必須です'
    if (reason === 'too_long') return '100 文字以内で入力してください'
    return `ステータス名が正しくありません (${reason})`
  }
  if (field === 'color') {
    if (reason === 'blank') return '色は必須です'
    if (reason === 'invalid') return '有効な HEX カラー（例: #3498DB）を入力してください'
    return `色が正しくありません (${reason})`
  }
  if (field === 'base' && reason === 'max_count_exceeded') {
    return 'ステータスは最大 10 件までです'
  }
  return reason
}

function selectPreset(preset: string) {
  color.value = preset
}
</script>

<template>
  <Dialog v-model:open="open">
    <DialogTrigger as-child>
      <Button variant="outline" size="sm">
        <Plus class="h-4 w-4" />
        ステータスを追加
      </Button>
    </DialogTrigger>
    <DialogContent class="sm:max-w-[480px]">
      <DialogHeader>
        <DialogTitle>新しいステータス</DialogTitle>
        <DialogDescription>
          名前と色を指定してボード末尾にステータス列を追加します。
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

        <!-- 名前 -->
        <div class="grid gap-1.5">
          <label for="status-name" class="text-sm font-medium leading-none">
            名前 <span class="text-red-600">*</span>
          </label>
          <input
            id="status-name"
            v-model="name"
            v-bind="nameAttrs"
            type="text"
            maxlength="100"
            class="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:opacity-50"
            :class="{ 'border-red-500 focus-visible:ring-red-500': errors.name }"
            placeholder="例) Pending Review"
            autocomplete="off"
          >
          <p v-if="open && errors.name" class="text-xs text-red-600">
            {{ errors.name }}
          </p>
        </div>

        <!-- 色（必須だが必ず初期値が入っているため * は付けない） -->
        <div class="grid gap-1.5">
          <label class="text-sm font-medium leading-none">
            色
          </label>
          <!-- プリセットスウォッチ。クリックで色コード入力欄も同期する。 -->
          <div class="flex flex-wrap gap-2">
            <button
              v-for="preset in STATUS_PRESET_COLORS"
              :key="preset"
              type="button"
              :aria-label="`色 ${preset}`"
              :aria-pressed="color === preset"
              class="h-7 w-7 rounded-md border-2 border-transparent transition-shadow hover:scale-105"
              :class="{ 'border-foreground ring-2 ring-foreground/30': color === preset }"
              :style="{ backgroundColor: preset }"
              @click="selectPreset(preset)"
            />
          </div>
          <!-- 色コード直接入力 + プレビュー矩形 -->
          <div class="mt-1 flex items-center gap-2">
            <label for="status-color-hex" class="text-xs text-muted-foreground">色コード</label>
            <input
              id="status-color-hex"
              v-model="color"
              v-bind="colorAttrs"
              type="text"
              maxlength="7"
              class="flex h-8 w-32 rounded-md border border-input bg-background px-2 py-1 font-mono text-sm shadow-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
              :class="{ 'border-red-500 focus-visible:ring-red-500': errors.color }"
              placeholder="#3498DB"
              autocomplete="off"
              spellcheck="false"
            >
            <span
              class="inline-block h-7 w-7 rounded-md border border-border"
              :style="{ backgroundColor: color }"
              aria-hidden="true"
            />
          </div>
          <p v-if="open && errors.color" class="text-xs text-red-600">
            {{ errors.color }}
          </p>
        </div>

        <DialogFooter>
          <Button
            type="submit"
            :disabled="mutation.isPending.value || !meta.valid"
          >
            {{ mutation.isPending.value ? '作成中…' : '作成' }}
          </Button>
        </DialogFooter>
      </form>
    </DialogContent>
  </Dialog>
</template>
