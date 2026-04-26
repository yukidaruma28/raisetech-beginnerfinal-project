<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useMutation, useQuery, useQueryClient } from '@tanstack/vue-query'
import { ChevronRight } from 'lucide-vue-next'
import { VueDraggable } from 'vue-draggable-plus'
import { fetchStatuses } from '~/lib/api/statuses'
import { fetchPriorities } from '~/lib/api/priorities'
import { fetchInquiries, moveInquiry, type MoveInquiryInput } from '~/lib/api/inquiries'
import type { Status } from '~/types/status'
import type { Priority } from '~/types/priority'
import type { Inquiry } from '~/types/inquiry'
import InquiryRow from './InquiryRow.vue'
import InquiryEditDialog from './InquiryEditDialog.vue'
import CreateStatusDialog from './CreateStatusDialog.vue'
import { STATUS_MAX_COUNT } from '~/lib/validation/status'

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

// VueDraggable は v-model で双方向バインドを要求するため、status ごとのローカル配列を持つ。
// inquiriesByStatus が更新されたら都度ローカルへ反映する（楽観的更新後の setQueryData も
// inquiriesByStatus 経由で流れてくる想定）。
const localLists = ref<Record<number, Inquiry[]>>({})
watch(
  inquiriesByStatus,
  (next) => {
    localLists.value = {}
    for (const [statusId, list] of Object.entries(next)) {
      localLists.value[Number(statusId)] = [...list]
    }
  },
  { immediate: true, deep: true },
)

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

// 詳細編集モーダルで開いている問い合わせ。クリックされた InquiryRow から渡される。
const editingId = ref<number | null>(null)
const editingInquiry = computed<Inquiry | null>(() => {
  if (editingId.value == null) return null
  return inquiriesQuery.data.value?.find(i => i.id === editingId.value) ?? null
})

function openEdit(inquiry: Inquiry) {
  editingId.value = inquiry.id
}

function closeEdit() {
  editingId.value = null
}

// ========== DnD ==========
const queryClient = useQueryClient()

const moveMutation = useMutation({
  mutationFn: ({ id, statusId, position }: { id: number } & MoveInquiryInput) =>
    moveInquiry(id, { statusId, position }),
  onMutate: async ({ id, statusId, position }) => {
    // 進行中の fetch をキャンセルしてからキャッシュを書き換える（後勝ちでちらつくのを防ぐ）。
    await queryClient.cancelQueries({ queryKey: ['inquiries'] })
    const prev = queryClient.getQueryData<Inquiry[]>(['inquiries'])
    if (prev) {
      queryClient.setQueryData<Inquiry[]>(
        ['inquiries'],
        optimisticReorder(prev, id, statusId, position),
      )
    }
    return { prev }
  },
  onError: (err, _vars, context) => {
    if (context?.prev) queryClient.setQueryData(['inquiries'], context.prev)
    // Toast は導入しないので console.warn でデバッグ可能にしておく。
    console.warn('Failed to move inquiry:', err)
  },
  onSettled: () => {
    queryClient.invalidateQueries({ queryKey: ['inquiries'] })
  },
})

// VueDraggable の @end ハンドラ。
// event.item は DOM 要素で、InquiryRow root に付けた data-inquiry-id から id を取得。
// event.to は移動先 VueDraggable の DOM、data-status-id 属性で新ステータスを判定。
// event.newIndex は 0-indexed なので +1 して 1-indexed の position に変換。
function handleDragEnd(event: { item: HTMLElement, to: HTMLElement, newIndex?: number, oldIndex?: number, from: HTMLElement }) {
  const movedId = Number(event.item.dataset.inquiryId)
  const newStatusId = Number((event.to as HTMLElement).dataset.statusId)
  const newPosition = (event.newIndex ?? 0) + 1
  if (!Number.isFinite(movedId) || !Number.isFinite(newStatusId)) return

  // 同列内で同じ位置にドロップ → 何もしない。
  if (event.from === event.to && event.oldIndex === event.newIndex) return

  moveMutation.mutate({ id: movedId, statusId: newStatusId, position: newPosition })
}

// 純関数：サーバ側 dense int 採番と同じロジックで vue-query キャッシュを並び替える。
function optimisticReorder(
  inquiries: Inquiry[],
  movedId: number,
  newStatusId: number,
  newPosition: number,
): Inquiry[] {
  const moved = inquiries.find(i => i.id === movedId)
  if (!moved) return inquiries
  const oldStatusId = moved.statusId

  // status_id ごとに分けつつ、自分は除外。
  const byStatus = new Map<number, Inquiry[]>()
  for (const inq of inquiries) {
    if (inq.id === movedId) continue
    const list = byStatus.get(inq.statusId) ?? []
    list.push(inq)
    byStatus.set(inq.statusId, list)
  }
  for (const list of byStatus.values()) {
    list.sort((a, b) => a.position - b.position || a.id - b.id)
  }

  // 移動先に挿入。
  const target = byStatus.get(newStatusId) ?? []
  const insertIndex = Math.min(Math.max(0, newPosition - 1), target.length)
  target.splice(insertIndex, 0, { ...moved, statusId: newStatusId })
  byStatus.set(newStatusId, target)

  // dense int で再採番（移動先 / 元 status の両方）。
  const renumber = (list: Inquiry[]) => list.map((inq, i) => ({ ...inq, position: i + 1 }))
  byStatus.set(newStatusId, renumber(byStatus.get(newStatusId) ?? []))
  if (oldStatusId !== newStatusId) {
    byStatus.set(oldStatusId, renumber(byStatus.get(oldStatusId) ?? []))
  }

  // flat。サーバ index 側は status_id, position, id 順なので一応それで並べる。
  const result: Inquiry[] = []
  const sortedStatusIds = [...byStatus.keys()].sort((a, b) => a - b)
  for (const sid of sortedStatusIds) {
    result.push(...(byStatus.get(sid) ?? []))
  }
  return result
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
          <!--
            VueDraggable は SSR で document を触る可能性があるので ClientOnly で包む。
            data-status-id を root に付けて、@end の event.to から新ステータスを取得する。
            handle セレクタで GripVertical アイコンだけドラッグ起点に限定。
          -->
          <ClientOnly>
            <VueDraggable
              v-if="localLists[status.id]"
              v-model="localLists[status.id]!"
              :data-status-id="status.id"
              :animation="150"
              group="inquiries"
              handle="[data-drag-handle]"
              ghost-class="opacity-30"
              @end="handleDragEnd"
            >
              <InquiryRow
                v-for="inquiry in (localLists[status.id] ?? [])"
                :key="inquiry.id"
                :data-inquiry-id="inquiry.id"
                :inquiry="inquiry"
                :status="status"
                :priority="priorityFor(inquiry)"
                @open="openEdit"
              />
            </VueDraggable>
          </ClientOnly>
        </div>
      </div>

      <!--
        ボード末尾の「+ ステータスを追加」UI（UC-06）。
        STATUS_MAX_COUNT に達したらボタンを隠して案内文に差し替える。
        reka-ui Dialog は SSR で IPC エラーを起こすため ClientOnly 必須。
      -->
      <div class="flex items-center justify-start border-t border-border bg-muted/20 px-4 py-3">
        <ClientOnly>
          <CreateStatusDialog
            v-if="(statusesQuery.data.value?.length ?? 0) < STATUS_MAX_COUNT"
          />
          <p v-else class="text-sm text-muted-foreground">
            ステータスは最大 {{ STATUS_MAX_COUNT }} 件までです
          </p>
        </ClientOnly>
      </div>
    </div>

    <!--
      reka-ui Dialog は SSR で IPC エラーを起こすので ClientOnly でラップする
      （UC-02 の CreateInquiryDialog と同じ落とし穴）。
      v-if で都度マウントすることで前回の編集 draft が残らないようにする。
    -->
    <ClientOnly>
      <InquiryEditDialog
        v-if="editingInquiry"
        :inquiry="editingInquiry"
        :statuses="statusesQuery.data.value ?? []"
        :priorities="prioritiesQuery.data.value ?? []"
        @close="closeEdit"
      />
    </ClientOnly>
  </section>
</template>
