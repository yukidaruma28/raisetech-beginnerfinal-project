"use client";

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { useState, type ReactNode } from "react";

/**
 * アプリ全体の Client Component プロバイダ。
 * Next.js App Router では Server Components がルートになるため、
 * TanStack Query の QueryClient はここでクライアント側に閉じて生成する。
 *
 * - `useState` で QueryClient を 1 度だけ初期化（レンダー毎に作り直さない）
 * - SSR フレンドリーな defaults（staleTime を多少持たせる）
 */
export function Providers({ children }: { children: ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 30 * 1000, // 30 秒は再フェッチしない
            refetchOnWindowFocus: false,
          },
        },
      })
  );

  return (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );
}
