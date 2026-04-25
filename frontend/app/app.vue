<script setup lang="ts">
import BoardListView from '~/components/board/BoardListView.vue'
import CreateInquiryDialog from '~/components/board/CreateInquiryDialog.vue'
</script>

<template>
  <div class="min-h-screen bg-background text-foreground">
    <header class="border-b">
      <div class="mx-auto flex max-w-7xl items-center px-6 py-5">
        <h1 class="text-2xl font-semibold">
          Inquiry Board
        </h1>
        <!--
          reka-ui の Dialog は SSR で IPC connection closed エラーを起こすため
          ClientOnly でラップする（CLAUDE.md の落とし穴メモ参照、過去 PR #16 の Collapsible と同様の対処）。
        -->
        <ClientOnly>
          <CreateInquiryDialog class="ml-auto" />
        </ClientOnly>
      </div>
    </header>
    <main class="mx-auto max-w-7xl px-6 py-6">
      <BoardListView />
    </main>
  </div>
</template>
