import { apiFetch } from "./client";
import type { Status } from "@/types/status";

/**
 * GET /api/statuses
 * ステータスを position 昇順で取得する。
 */
export async function fetchStatuses(): Promise<Status[]> {
  return apiFetch<Status[]>("/statuses");
}

/**
 * TanStack Query の queryKey 規約。
 * 後続でキャッシュ無効化やプレフィックス検索を行う際の起点になる。
 */
export const statusesQueryKeys = {
  all: ["statuses"] as const,
  list: () => [...statusesQueryKeys.all, "list"] as const,
};
