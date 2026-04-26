<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useMutation, useQueryClient } from '@tanstack/vue-query'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { ApiError } from '~/lib/api/client'
import { deleteStatus } from '~/lib/api/statuses'
import type { Status } from '~/types/status'

const props = defineProps<{
  open: boolean
  status: Status
  inquiryCount: number
  otherStatuses: Status[]
}>()

const emit = defineEmits<{
  (e: 'update:open', value: boolean): void
  (e: 'deleted'): void
}>()

const open = computed({
  get: () => props.open,
  set: (v) => emit('update:open', v),
})

const requiresMoveTo = computed(() => props.inquiryCount > 0)
const moveToId = ref<number | null>(null)
const serverError = ref<string | null>(null)

// open / props 変化に応じて初期値を整える。
// 移動先 select は他 status の先頭を初期選択する。
watch(
  () => [props.open, props.otherStatuses] as const,
  ([isOpen]) => {
    if (!isOpen) return
    serverError.value = null
    moveToId.value = props.otherStatuses[0]?.id ?? null
  },
  { immediate: true },
)

const queryClient = useQueryClient()

const mutation = useMutation({
  mutationFn: () => deleteStatus(
    props.status.id,
    requiresMoveTo.value ? (moveToId.value ?? undefined) : undefined,
  ),
  onSuccess: () => {
    queryClient.invalidateQueries({ queryKey: ['statuses'] })
    queryClient.invalidateQueries({ queryKey: ['inquiries'] })
    emit('deleted')
    open.value = false
  },
  onError: (err) => {
    serverError.value = humanizeError(err)
  },
})

function confirmDelete() {
  if (mutation.isPending.value) return
  if (requiresMoveTo.value && moveToId.value == null) {
    serverError.value = '移動先のステータスを選択してください'
    return
  }
  serverError.value = null
  mutation.mutate()
}

// サーバ側のエラー応答（404 / 409 / 422）をユーザ向け文言に変換する。
function humanizeError(err: unknown): string {
  if (err instanceof ApiError) {
    if (err.status === 404) {
      const detail = err.payload?.details?.find(d => d.field === 'moveTo')
      if (detail) return '指定した移動先ステータスが見つかりません。一覧を再読み込みしてください。'
      return 'ステータスが見つかりません。すでに削除されている可能性があります。'
    }
    if (err.status === 409) {
      return '所属する問い合わせがあるため、移動先ステータスを指定してください。'
    }
    if (err.status === 422) {
      const detail = err.payload?.details?.find(d => d.field === 'moveTo')
      if (detail?.reason === 'cannot_move_to_self') {
        return '自分自身は移動先に指定できません。'
      }
      return err.payload?.message ?? '入力内容を確認してください。'
    }
    return err.payload?.message ?? `削除に失敗しました（HTTP ${err.status}）`
  }
  return err instanceof Error ? err.message : '削除に失敗しました'
}
</script>

<template>
  <Dialog v-model:open="open">
    <DialogContent class="sm:max-w-[460px]">
      <DialogHeader>
        <DialogTitle class="text-base">
          「{{ status.name }}」を削除しますか？
        </DialogTitle>
        <DialogDescription>
          <span v-if="requiresMoveTo">
            このステータスには {{ inquiryCount }} 件の問い合わせが含まれています。
            別のステータスへ移動した上で削除します。
          </span>
          <span v-else>
            このステータスを削除します。元には戻せません。
          </span>
        </DialogDescription>
      </DialogHeader>

      <div
        v-if="serverError"
        class="rounded-md border border-red-500/40 bg-red-50 px-3 py-2 text-sm text-red-700"
        role="alert"
      >
        {{ serverError }}
      </div>

      <div v-if="requiresMoveTo" class="grid gap-1.5">
        <label for="delete-status-move-to" class="text-sm font-medium leading-none">
          移動先のステータス <span class="text-red-600">*</span>
        </label>
        <select
          id="delete-status-move-to"
          v-model="moveToId"
          class="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
        >
          <option
            v-for="s in otherStatuses"
            :key="s.id"
            :value="s.id"
          >
            {{ s.name }}
          </option>
        </select>
        <p v-if="otherStatuses.length === 0" class="text-xs text-red-600">
          他のステータスがありません。先にステータスを追加してください。
        </p>
      </div>

      <DialogFooter>
        <Button
          type="button"
          variant="outline"
          :disabled="mutation.isPending.value"
          @click="open = false"
        >
          キャンセル
        </Button>
        <Button
          type="button"
          class="bg-red-600 text-white hover:bg-red-700"
          :disabled="mutation.isPending.value
            || (requiresMoveTo && (otherStatuses.length === 0 || moveToId == null))"
          @click="confirmDelete"
        >
          {{ mutation.isPending.value ? '削除中…' : '削除' }}
        </Button>
      </DialogFooter>
    </DialogContent>
  </Dialog>
</template>
