// API レイヤ共通のエラー型。
// 422 / 404 / 400 などサーバが返す `{ error, message, details }` を
// UI 側でそのまま読めるよう payload を保持する。
export class ApiError extends Error {
  public readonly status: number
  public readonly payload: ApiErrorPayload | null

  constructor(status: number, payload: ApiErrorPayload | null, message: string) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.payload = payload
  }
}

export interface ApiErrorDetail {
  field: string
  reason: string
}

export interface ApiErrorPayload {
  error?: string
  message?: string
  details?: ApiErrorDetail[]
}

export function apiUrl(path: string): string {
  const config = useRuntimeConfig()
  const base = config.public.apiBaseUrl.replace(/\/$/, '')
  const normalized = path.startsWith('/') ? path : `/${path}`
  return `${base}${normalized}`
}

export async function apiFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(apiUrl(path), {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      ...(init?.headers ?? {}),
    },
  })

  if (!res.ok) {
    const payload = await safeReadJson(res)
    const message = payload?.message
      ?? `API request failed: ${res.status} ${res.statusText}`
    throw new ApiError(res.status, payload, message)
  }

  // 204 No Content / 205 Reset Content は body 無しなので JSON.parse すると失敗する。
  // 呼び出し側が void を期待している前提で undefined を返す。
  if (res.status === 204 || res.status === 205) {
    return undefined as T
  }

  return res.json() as Promise<T>
}

// JSON のパースに失敗してもエラーで落ちないよう吸収する。
// 422 でもサーバが空ボディを返すケースを考慮。
async function safeReadJson(res: Response): Promise<ApiErrorPayload | null> {
  try {
    return (await res.json()) as ApiErrorPayload
  }
  catch {
    return null
  }
}
