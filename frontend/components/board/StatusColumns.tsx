"use client";

import { useQuery } from "@tanstack/react-query";
import { fetchStatuses, statusesQueryKeys } from "@/lib/api/statuses";
import type { Status } from "@/types/status";

/**
 * カンバンボードの列ヘッダー一覧。
 * 最初の vertical slice では「列ヘッダーだけ」を表示し、後続で
 * 各列の中身（Inquiry カード）を埋めていく。
 */
export function StatusColumns() {
  const {
    data: statuses,
    isLoading,
    isError,
    error,
  } = useQuery({
    queryKey: statusesQueryKeys.list(),
    queryFn: fetchStatuses,
  });

  if (isLoading) {
    return (
      <div className="text-zinc-500" role="status">
        ステータスを読み込み中...
      </div>
    );
  }

  if (isError) {
    return (
      <div className="text-red-600" role="alert">
        ステータスの取得に失敗しました: {error instanceof Error ? error.message : String(error)}
      </div>
    );
  }

  if (!statuses || statuses.length === 0) {
    return (
      <div className="text-zinc-500">ステータスが登録されていません。</div>
    );
  }

  return (
    <div className="flex gap-4 overflow-x-auto p-4">
      {statuses.map((status) => (
        <StatusColumnHeader key={status.id} status={status} />
      ))}
    </div>
  );
}

function StatusColumnHeader({ status }: { status: Status }) {
  return (
    <div className="flex w-64 shrink-0 flex-col rounded-lg border border-zinc-200 bg-zinc-50 dark:border-zinc-800 dark:bg-zinc-900">
      <div className="flex items-center gap-2 px-4 py-3">
        <span
          aria-hidden
          className="inline-block h-3 w-3 rounded-full"
          style={{ backgroundColor: status.color }}
        />
        <h2 className="text-sm font-semibold text-zinc-800 dark:text-zinc-100">
          {status.name}
        </h2>
      </div>
      <div className="min-h-[120px] px-4 pb-4 text-xs text-zinc-400">
        （カードは未実装）
      </div>
    </div>
  );
}
