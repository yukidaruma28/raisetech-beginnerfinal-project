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
    throw new Error(`API request failed: ${res.status} ${res.statusText}`)
  }

  return res.json() as Promise<T>
}
