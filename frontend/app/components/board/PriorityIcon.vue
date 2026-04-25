<script setup lang="ts">
import { computed } from 'vue'
import type { Priority } from '~/types/priority'

const props = defineProps<{
  priority: Priority
}>()

// 3 段階運用:
// level 1 = 高（赤）/ level 2 = 中（黄）/ level 3 = 低（青）
// priority.name はサーバ側で「高/中/低」になる想定。フォールバックで level → 漢字をマッピング。
const label = computed(() => {
  if (props.priority.name) return props.priority.name
  switch (props.priority.level) {
    case 1: return '高'
    case 2: return '中'
    case 3: return '低'
    default: return '?'
  }
})
</script>

<template>
  <span
    class="inline-flex h-6 w-6 shrink-0 items-center justify-center rounded text-xs font-bold tabular-nums"
    :style="{ color: priority.color, backgroundColor: `${priority.color}1A` }"
    :aria-label="`優先度: ${label}`"
    :title="`優先度: ${label}`"
  >
    {{ label }}
  </span>
</template>
