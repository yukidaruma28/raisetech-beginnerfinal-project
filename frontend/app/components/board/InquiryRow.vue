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
    checkbox（UC-04 選択用）と PriorityIcon（後続のクイック変更用）は
    クリックで親への伝播を止め、誤って編集モーダルが開かないようにする。
  -->
  <div
    role="button"
    tabindex="0"
    :aria-label="`問い合わせ ${inquiry.id} を編集`"
    class="group flex cursor-pointer items-center gap-3 border-b border-border/40 px-6 py-2.5 text-base hover:bg-muted/30 focus-visible:bg-muted/30 focus-visible:outline-none"
    @click="emit('open', inquiry)"
    @keydown.enter.space.prevent="emit('open', inquiry)"
  >
    <!--
      ドラッグハンドル。data-drag-handle を vue-draggable-plus の handle セレクタで拾う。
      hover 時のみ表示し、@click.stop で行クリック（編集モーダル）から伝播を遮断。
      handle 配下の要素も Sortable.js が drag 起点として認識するので、アイコン全体が
      data 属性配下に入っていれば OK。
    -->
    <span
      data-drag-handle
      class="shrink-0 cursor-grab text-muted-foreground opacity-0 transition-opacity group-hover:opacity-100 active:cursor-grabbing"
      :aria-label="`タスク ${inquiry.id} を並び替え`"
      @click.stop
    >
      <GripVertical class="h-4 w-4" />
    </span>

    <input
      type="checkbox"
      class="h-4 w-4 shrink-0 cursor-pointer rounded border-border opacity-0 transition-opacity group-hover:opacity-100"
      :aria-label="`タスク ${inquiry.id} を選択`"
      @click.stop
    >

    <PriorityIcon v-if="priority" :priority="priority" @click.stop />

    <span class="w-20 shrink-0 font-mono text-sm text-muted-foreground">
      TASK-{{ inquiry.id }}
    </span>

    <span
      class="inline-block h-3 w-3 shrink-0 rounded-full"
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
