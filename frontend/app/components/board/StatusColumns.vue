<script setup lang="ts">
import { useQuery } from '@tanstack/vue-query'
import { fetchStatuses } from '~/lib/api/statuses'
import type { Status } from '~/types/status'

const { data, isLoading, isError, error } = useQuery<Status[]>({
  queryKey: ['statuses'],
  queryFn: fetchStatuses,
})
</script>

<template>
  <section>
    <div v-if="isLoading" class="text-sm text-muted-foreground">
      ステータスを読み込み中…
    </div>
    <div v-else-if="isError" class="text-sm text-destructive">
      ステータスの読み込みに失敗しました: {{ error?.message }}
    </div>
    <div
      v-else-if="data"
      class="flex gap-4 overflow-x-auto pb-4"
    >
      <div
        v-for="status in data"
        :key="status.id"
        class="flex w-72 shrink-0 flex-col gap-2 rounded-md border bg-card p-3"
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
        </div>
        <p class="text-xs text-muted-foreground">
          position: {{ status.position }}
        </p>
      </div>
    </div>
  </section>
</template>
