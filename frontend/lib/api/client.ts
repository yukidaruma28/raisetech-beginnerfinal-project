/**
 * Rails API のベース URL を一元管理する。
 * 開発時は http://localhost:3001/api、本番では `NEXT_PUBLIC_API_BASE_URL` を注入する想定。
 */
export const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:3001/api";

/**
 * fetch のラッパー。
 * - URL は `API_BASE_URL` に対する相対パスで指定する（例: "/statuses"）
 * - 非 2xx レスポンスは Error にして reject する
 * - JSON レスポンスを自動で parse する
 */
export async function apiFetch<T>(
  path: string,
  init?: RequestInit
): Promise<T> {
  const url = `${API_BASE_URL}${path}`;
  const response = await fetch(url, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      ...(init?.headers ?? {}),
    },
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(
      `API request failed: ${response.status} ${response.statusText} - ${text}`
    );
  }

  // 204 No Content や空レスポンスの場合は undefined を返す（呼び出し側で型保証）。
  if (response.status === 204) {
    return undefined as T;
  }

  return (await response.json()) as T;
}
