<script setup lang="ts">
import { GripVertical } from 'lucide-vue-next'
import type { Inquiry } from '~/types/inquiry'
import type { Status } from '~/types/status'
import type { Priority } from '~/types/priority'
import PriorityIcon from './PriorityIcon.vue'

defineProps<{
  inquiry: Inquiry
  status: Status
  // priority は必須だが、lookup 失敗時の防御として undefined を許容。
  priority: Priority | undefined
}>()

const emit = defineEmits<{ open: [inquiry: Inquiry] }>()

function formatDate(iso: string | undefined): string {
  if (!iso) return ''
  const date = new Date(iso)
  return new Intl.DateTimeFormat('ja-JP', {
    month: 'short',
    day: 'numeric',
  }).format(date)
}
</script>

<template>
  <!--
    Inquiry 行全体を「ボタン化」して詳細モーダル（編集）を開く。
    PriorityIcon（後続のクイック変更用）はクリックで親への伝播を止め、
    誤って編集モーダルが開かないようにする。
  -->
  <div
    role="button"
    tabindex="0"
    :aria-label="`作品 ${inquiry.id} を編集`"
    class="group mx-2 my-1 flex cursor-pointer items-center gap-3 rounded-md border border-border/40 bg-card px-4 py-3 text-base transition-colors hover:border-border hover:bg-muted/40 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
    @click="emit('open', inquiry)"
    @keydown.enter.space.prevent="emit('open', inquiry)"
  >
    <!--
      ドラッグハンドル。data-drag-handle を vue-draggable-plus の handle セレクタで拾う。
      hover 時のみ表示し、@click.stop で行クリック（編集モーダル）から伝播を遮断。
    -->
    <span
      data-drag-handle
      class="shrink-0 cursor-grab text-muted-foreground opacity-0 transition-opacity group-hover:opacity-60 active:cursor-grabbing"
      :aria-label="`作品 ${inquiry.id} を並び替え`"
      @click.stop
    >
      <GripVertical class="h-4 w-4" />
    </span>

    <PriorityIcon v-if="priority" :priority="priority" @click.stop />

    <span class="w-16 shrink-0 font-mono text-sm text-muted-foreground">
      作品-{{ inquiry.id }}
    </span>

    <span
      class="inline-block h-2.5 w-2.5 shrink-0 rounded-full"
      :style="{ backgroundColor: status.color }"
      :title="status.name"
      aria-hidden="true"
    />

    <span class="min-w-0 flex-1 truncate text-foreground">
      {{ inquiry.title }}
    </span>

    <span class="shrink-0 text-sm text-muted-foreground tabular-nums">
      {{ formatDate(inquiry.createdAt) }}
    </span>
  </div>
</template>
