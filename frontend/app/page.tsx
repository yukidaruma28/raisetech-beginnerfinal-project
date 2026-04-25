import { StatusColumns } from "@/components/board/StatusColumns";

export default function Home() {
  return (
    <main className="flex flex-1 flex-col bg-zinc-50 dark:bg-zinc-950">
      <header className="border-b border-zinc-200 px-6 py-4 dark:border-zinc-800">
        <h1 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
          Inquiry Board
        </h1>
        <p className="text-xs text-zinc-500">
          Status の vertical slice — Rails API から取得したステータスを列ヘッダーとして表示します
        </p>
      </header>
      <StatusColumns />
    </main>
  );
}
