<script setup lang="ts">
import { computed } from 'vue'
import { useQuery } from '@tanstack/vue-query'
import { fetchStatuses } from '~/lib/api/statuses'
import { fetchInquiries } from '~/lib/api/inquiries'
import type { Status } from '~/types/status'
import type { Inquiry } from '~/types/inquiry'
import InquiryCard from './InquiryCard.vue'

// statuses と inquiries は独立に並列で取得する。失敗・ロード状態は両方を集約して表示。
const statusesQuery = useQuery<Status[]>({
  queryKey: ['statuses'],
  queryFn: fetchStatuses,
})

const inquiriesQuery = useQuery<Inquiry[]>({
  queryKey: ['inquiries'],
  queryFn: fetchInquiries,
})

const isLoading = computed(() => statusesQuery.isLoading.value || inquiriesQuery.isLoading.value)
const isError   = computed(() => statusesQuery.isError.value   || inquiriesQuery.isError.value)
const errorMessage = computed(() => {
  return statusesQuery.error.value?.message
      ?? inquiriesQuery.error.value?.message
      ?? '不明なエラー'
})

// inquiries を status_id で groupBy。API 側で position 順に並んでいる前提だが、
// 念のためフロント側でも position 昇順にソートしておく（防御的）。
const inquiriesByStatus = computed<Record<number, Inquiry[]>>(() => {
  const map: Record<number, Inquiry[]> = {}
  for (const inquiry of inquiriesQuery.data.value ?? []) {
    if (!map[inquiry.statusId]) {
      map[inquiry.statusId] = []
    }
    map[inquiry.statusId]!.push(inquiry)
  }
  for (const list of Object.values(map)) {
    list.sort((a, b) => a.position - b.position)
  }
  return map
})
</script>

<template>
  <section>
    <div v-if="isLoading" class="text-sm text-muted-foreground">
      ボードを読み込み中…
    </div>
    <div v-else-if="isError" class="text-sm text-destructive">
      ボードの読み込みに失敗しました: {{ errorMessage }}
    </div>
    <div
      v-else-if="statusesQuery.data.value"
      class="flex gap-4 overflow-x-auto pb-4"
    >
      <div
        v-for="status in statusesQuery.data.value"
        :key="status.id"
        class="flex w-72 shrink-0 flex-col gap-3 rounded-md border bg-card p-3"
      >
        <div class="flex items-center gap-2">
          <span
            class="inline-block h-3 w-3 rounded-full"
            :style="{ backgroundColor: status.color }"
            aria-hidden="true"
          />
          <h3 class="text-sm font-semibold">
            {{ status.name }}
          </h3>
          <span class="ml-auto text-xs text-muted-foreground">
            {{ inquiriesByStatus[status.id]?.length ?? 0 }}
          </span>
        </div>

        <div class="flex flex-col gap-2">
          <InquiryCard
            v-for="inquiry in inquiriesByStatus[status.id] ?? []"
            :key="inquiry.id"
            :inquiry="inquiry"
          />
          <p
            v-if="!inquiriesByStatus[status.id]?.length"
            class="text-xs text-muted-foreground"
          >
            問い合わせはありません
          </p>
        </div>
      </div>
    </div>
  </section>
</template>
