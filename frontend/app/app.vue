<script setup lang="ts">
import { Film } from 'lucide-vue-next'
import BoardListView from '~/components/board/BoardListView.vue'
import CreateInquiryDialog from '~/components/board/CreateInquiryDialog.vue'

useHead({ htmlAttrs: { class: 'dark' } })
</script>

<template>
  <div class="min-h-screen bg-background text-foreground">
    <header class="sticky top-0 z-10 border-b border-border/50 bg-card/90 backdrop-blur">
      <div class="mx-auto flex max-w-7xl items-center gap-3 px-6 py-4">
        <Film class="h-5 w-5 shrink-0 text-primary" aria-hidden="true" />
        <h1 class="text-lg font-bold tracking-tight">
          視聴管理ボード
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
