<script setup lang="ts">
import type { Inquiry } from '~/types/inquiry'
import type { Status } from '~/types/status'

defineProps<{
  inquiry: Inquiry
  status: Status
}>()

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
  <div
    class="group flex items-center gap-3 border-b border-border/40 px-6 py-2 text-sm hover:bg-muted/30"
  >
    <input
      type="checkbox"
      class="h-4 w-4 shrink-0 cursor-pointer rounded border-border opacity-0 transition-opacity group-hover:opacity-100"
      :aria-label="`問い合わせ ${inquiry.id} を選択`"
    >

    <span class="w-16 shrink-0 font-mono text-xs text-muted-foreground">
      INQ-{{ inquiry.id }}
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

    <span class="shrink-0 text-xs text-muted-foreground tabular-nums">
      {{ formatDate(inquiry.createdAt) }}
    </span>
  </div>
</template>
