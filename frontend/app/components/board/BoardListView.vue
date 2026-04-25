<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useQuery } from '@tanstack/vue-query'
import { ChevronRight } from 'lucide-vue-next'
import { fetchStatuses } from '~/lib/api/statuses'
import { fetchPriorities } from '~/lib/api/priorities'
import { fetchInquiries } from '~/lib/api/inquiries'
import type { Status } from '~/types/status'
import type { Priority } from '~/types/priority'
import type { Inquiry } from '~/types/inquiry'
import InquiryRow from './InquiryRow.vue'

const statusesQuery = useQuery<Status[]>({
  queryKey: ['statuses'],
  queryFn: fetchStatuses,
})

const prioritiesQuery = useQuery<Priority[]>({
  queryKey: ['priorities'],
  queryFn: fetchPriorities,
})

const inquiriesQuery = useQuery<Inquiry[]>({
  queryKey: ['inquiries'],
  queryFn: fetchInquiries,
})

const isLoading = computed(() =>
  statusesQuery.isLoading.value
  || prioritiesQuery.isLoading.value
  || inquiriesQuery.isLoading.value,
)
const isError = computed(() =>
  statusesQuery.isError.value
  || prioritiesQuery.isError.value
  || inquiriesQuery.isError.value,
)
const errorMessage = computed(() => {
  return statusesQuery.error.value?.message
    ?? prioritiesQuery.error.value?.message
    ?? inquiriesQuery.error.value?.message
    ?? '不明なエラー'
})

// priority_id から Priority を引くための Map。
const prioritiesById = computed<Map<number, Priority>>(() => {
  const map = new Map<number, Priority>()
  for (const p of prioritiesQuery.data.value ?? []) {
    map.set(p.id, p)
  }
  return map
})

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

const openMap = ref<Record<number, boolean>>({})

watch(
  () => statusesQuery.data.value,
  (statuses) => {
    if (!statuses) return
    for (const status of statuses) {
      if (openMap.value[status.id] === undefined) {
        openMap.value[status.id] = true
      }
    }
  },
  { immediate: true },
)

function toggle(statusId: number) {
  openMap.value[statusId] = !openMap.value[statusId]
}

// priority は必須だが、lookup に失敗した場合は undefined を返してテンプレ側で握りつぶす（防御的）
function priorityFor(inquiry: Inquiry): Priority | undefined {
  return prioritiesById.value.get(inquiry.priorityId)
}
</script>

<template>
  <section class="rounded-md border bg-card">
    <div v-if="isLoading" class="px-6 py-4 text-base text-muted-foreground">
      ボードを読み込み中…
    </div>
    <div v-else-if="isError" class="px-6 py-4 text-base text-destructive">
      ボードの読み込みに失敗しました: {{ errorMessage }}
    </div>
    <div v-else-if="statusesQuery.data.value">
      <div
        v-for="status in statusesQuery.data.value"
        :key="status.id"
        class="border-b border-border last:border-b-0"
      >
        <button
          type="button"
          class="flex w-full items-center gap-2 px-4 py-3 text-left hover:bg-muted/40"
          :aria-expanded="openMap[status.id] ?? true"
          @click="toggle(status.id)"
        >
          <ChevronRight
            class="h-4 w-4 text-muted-foreground transition-transform duration-150"
            :class="{ 'rotate-90': openMap[status.id] }"
            aria-hidden="true"
          />
          <span
            class="inline-block h-3 w-3 rounded-full"
            :style="{ backgroundColor: status.color }"
            aria-hidden="true"
          />
          <span class="text-base font-semibold text-foreground">
            {{ status.name }}
          </span>
          <span class="text-sm text-muted-foreground tabular-nums">
            {{ inquiriesByStatus[status.id]?.length ?? 0 }}
          </span>
        </button>

        <div v-show="openMap[status.id]">
          <div
            v-if="!inquiriesByStatus[status.id]?.length"
            class="px-6 py-2 text-sm text-muted-foreground"
          >
            該当なし
          </div>
          <InquiryRow
            v-for="inquiry in inquiriesByStatus[status.id] ?? []"
            :key="inquiry.id"
            :inquiry="inquiry"
            :status="status"
            :priority="priorityFor(inquiry)"
          />
        </div>
      </div>
    </div>
  </section>
</template>
