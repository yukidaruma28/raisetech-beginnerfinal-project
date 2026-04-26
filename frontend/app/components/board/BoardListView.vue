<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useMutation, useQuery, useQueryClient } from '@tanstack/vue-query'
import { ChevronRight, GripVertical, Trash2 } from 'lucide-vue-next'
import { VueDraggable } from 'vue-draggable-plus'
import { fetchStatuses, moveStatus } from '~/lib/api/statuses'
import { fetchPriorities } from '~/lib/api/priorities'
import { fetchInquiries, moveInquiry, type MoveInquiryInput } from '~/lib/api/inquiries'
import type { Status } from '~/types/status'
import type { Priority } from '~/types/priority'
import type { Inquiry } from '~/types/inquiry'
import InquiryRow from './InquiryRow.vue'
import InquiryEditDialog from './InquiryEditDialog.vue'
import CreateStatusDialog from './CreateStatusDialog.vue'
import DeleteStatusDialog from './DeleteStatusDialog.vue'
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

// VueDraggable は :list バインドで配列を直接ミューテートする。
// Issue #33 のゴースト/複製バグの根本対策として、以下 3 点を遵守する:
//   1. localLists.value (Record) は **コンポーネントのライフタイム内で再代入しない**。
//      キーの追加・削除は localLists.value[id] = [] / Reflect.deleteProperty で in-place。
//   2. 各 status の配列も **一度生成したら同じ参照のまま splice で中身だけ更新**。
//      `[...list]` で新しい配列に置き換えると vue-draggable-plus 内部の Sortable
//      が DOM 同期に失敗してゴースト/複製が発生する（過去の試行で再現確認済み）。
//   3. vue-draggable-plus は :list モードを使い、emit/setter ではなく直接 splice させる。
//      v-model だと 2 重ソース（emit setter + watcher）が同じ配列を奪い合って壊れる。
const localLists = ref<Record<number, Inquiry[]>>({})

// Watcher A: status の追加/削除に追随して localLists のキーだけ管理する（配列参照は不変）。
watch(
  () => statusesQuery.data.value,
  (statuses) => {
    if (!statuses) return
    const validIds = new Set(statuses.map(s => s.id))
    for (const status of statuses) {
      if (!localLists.value[status.id]) {
        localLists.value[status.id] = []
      }
    }
    for (const idStr of Object.keys(localLists.value)) {
      if (!validIds.has(Number(idStr))) {
        Reflect.deleteProperty(localLists.value, idStr)
      }
    }
  },
  { immediate: true },
)

// Watcher B: サーバ側 inquiries が変わったら、各 status の配列を **同じ参照のまま splice** で同期。
// inquiriesByStatus は毎回新しいオブジェクト参照を返すため deep: true は不要。
watch(
  inquiriesByStatus,
  (next) => {
    for (const status of statusesQuery.data.value ?? []) {
      const target = localLists.value[status.id]
      if (!target) continue
      const serverList = next[status.id] ?? []
      target.splice(0, target.length, ...serverList)
    }
  },
  { immediate: true },
)

// ステータス列の並び替え DnD 用ローカルリスト。
// Inquiry の localLists と同パターン: サーバデータを splice で同期し参照は不変。
const localStatuses = ref<Status[]>([])

watch(
  () => statusesQuery.data.value,
  (statuses) => {
    if (!statuses) return
    localStatuses.value.splice(0, localStatuses.value.length, ...statuses)
  },
  { immediate: true },
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

// ステータス削除ダイアログ。開いている status を id で保持する。
const deletingStatusId = ref<number | null>(null)
const deletingStatus = computed<Status | null>(() => {
  if (deletingStatusId.value == null) return null
  return statusesQuery.data.value?.find(s => s.id === deletingStatusId.value) ?? null
})
const deletingInquiryCount = computed(() => {
  if (deletingStatus.value == null) return 0
  return inquiriesByStatus.value[deletingStatus.value.id]?.length ?? 0
})
const deletingOtherStatuses = computed<Status[]>(() => {
  if (deletingStatus.value == null) return []
  return (statusesQuery.data.value ?? []).filter(s => s.id !== deletingStatus.value!.id)
})

function openDelete(status: Status) {
  deletingStatusId.value = status.id
}

function handleDeleteOpenChange(value: boolean) {
  if (!value) deletingStatusId.value = null
}

// ========== DnD ==========
//
// 楽観的更新は Issue #33 対応で撤去した。理由:
//   vue-draggable-plus が drop 時に DOM を物理移動 + v-model 配列を splice する一方、
//   楽観的 setQueryData が watcher 経由で localLists を全置換すると「2 つのソース」
//   から DOM が二重に書き換えられて、空ステータスを跨ぐ移動でゴーストや複製が発生した。
//
// dragKey による VueDraggable 強制再マウント（Issue #33 最終対策）:
//   API 応答後に dragKey をインクリメントすることで各 VueDraggable の :key が変わり、
//   Vue が旧 SortableJS インスタンスを破棄して新インスタンスを生成し直す。
//   ドラッグ後に残るゴースト/複製 DOM は完全にクリアされる。
const queryClient = useQueryClient()

const dragKey = ref(0)

const moveMutation = useMutation({
  mutationFn: ({ id, statusId, position }: { id: number } & MoveInquiryInput) =>
    moveInquiry(id, { statusId, position }),
  onError: (err) => {
    // Toast は導入しないので console.warn でデバッグ可能にしておく。
    console.warn('Failed to move inquiry:', err)
  },
  onSettled: () => {
    queryClient.invalidateQueries({ queryKey: ['inquiries'] })
    dragKey.value++
  },
})

const statusDragKey = ref(0)

const statusMoveMutation = useMutation({
  mutationFn: ({ id, position }: { id: number; position: number }) =>
    moveStatus(id, position),
  onError: (err) => console.warn('Failed to move status:', err),
  onSettled: () => {
    queryClient.invalidateQueries({ queryKey: ['statuses'] })
    statusDragKey.value++
  },
})

function handleStatusDragEnd(event: { oldIndex?: number; newIndex?: number; item: HTMLElement }) {
  if (event.oldIndex === event.newIndex) return
  const movedId = Number(event.item.dataset.statusId)
  const newPosition = (event.newIndex ?? 0) + 1
  if (!Number.isFinite(movedId) || movedId === 0) return
  statusMoveMutation.mutate({ id: movedId, position: newPosition })
}

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
      <ClientOnly>
        <VueDraggable
          :key="`statuses-${statusDragKey}`"
          :list="localStatuses"
          :model-value="localStatuses"
          group="statuses"
          handle="[data-status-drag-handle]"
          ghost-class="opacity-30"
          :animation="150"
          @end="handleStatusDragEnd"
        >
          <div
            v-for="status in localStatuses"
            :key="status.id"
            :data-status-id="status.id"
            class="border-b border-border last:border-b-0"
          >
        <!--
          ヘッダー行。トグル用 <button> と削除用 <button> が並ぶ独立要素になっているため
          group / hover でゴミ箱アイコンを表示する（InquiryRow のドラッグハンドルと同パターン）。
        -->
        <div class="group flex w-full items-center hover:bg-muted/40">
          <span
            data-status-drag-handle
            class="ml-2 cursor-grab opacity-0 group-hover:opacity-100 text-muted-foreground"
            aria-hidden="true"
          >
            <GripVertical class="h-4 w-4" />
          </span>
          <button
            type="button"
            class="flex flex-1 items-center gap-2 px-4 py-3 text-left"
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
          <button
            type="button"
            class="mr-2 inline-flex h-7 w-7 items-center justify-center rounded text-muted-foreground opacity-0 transition-opacity hover:bg-red-50 hover:text-red-600 group-hover:opacity-100 focus-visible:opacity-100"
            :aria-label="`「${status.name}」を削除`"
            @click.stop="openDelete(status)"
          >
            <Trash2 class="h-4 w-4" />
          </button>
        </div>

        <div v-show="openMap[status.id]" class="relative">
          <!--
            VueDraggable は SSR で document を触る可能性があるので ClientOnly で包む。
            data-status-id を root に付けて、@end の event.to から新ステータスを取得する。
            handle セレクタで GripVertical アイコンだけドラッグ起点に限定。

            空列対応（Issue #33）:
              - VueDraggable コンテナに class="min-h-[56px]" を当て、空配列でも
                drop target になる物理的な領域を確保する。
              - empty-insert-threshold を Sortable のデフォルト 5px → 40px に拡げ、
                カーソルが近接するだけで insert を受け付けるようにする。
              - 「該当なし」テキストは VueDraggable の sibling として配置し、
                親 div を relative にした上で absolute + pointer-events-none で
                空 drop 領域に視覚的に重ねる（drag イベントを邪魔しない）。
          -->
          <ClientOnly>
            <VueDraggable
              v-if="localLists[status.id]"
              :key="`${status.id}-${dragKey}`"
              :list="localLists[status.id]!"
              :model-value="localLists[status.id]!"
              :data-status-id="status.id"
              :animation="150"
              group="inquiries"
              handle="[data-drag-handle]"
              ghost-class="opacity-30"
              :empty-insert-threshold="40"
              class="min-h-[56px]"
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
          <div
            v-if="!inquiriesByStatus[status.id]?.length"
            class="pointer-events-none absolute inset-x-0 top-0 flex h-[56px] items-center px-6 text-sm italic text-muted-foreground"
          >
            該当なし（ここにドロップで移動できます）
          </div>
        </div>
          </div>
        </VueDraggable>
      </ClientOnly>

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

    <!--
      ステータス削除ダイアログ。reka-ui Dialog は SSR で IPC エラーになるため ClientOnly。
      v-if で都度マウントすることで前回の選択 state を残さない。
    -->
    <ClientOnly>
      <DeleteStatusDialog
        v-if="deletingStatus"
        :open="true"
        :status="deletingStatus"
        :inquiry-count="deletingInquiryCount"
        :other-statuses="deletingOtherStatuses"
        @update:open="handleDeleteOpenChange"
      />
    </ClientOnly>
  </section>
</template>
