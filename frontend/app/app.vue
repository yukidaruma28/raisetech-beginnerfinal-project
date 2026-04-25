<script setup lang="ts">
import StatusColumns from '~/components/board/StatusColumns.vue'
</script>

<template>
  <div class="min-h-screen bg-background text-foreground">
    <header class="border-b">
      <div class="mx-auto flex max-w-7xl items-center px-6 py-4">
        <h1 class="text-xl font-semibold">
          Inquiry Board
        </h1>
      </div>
    </header>
    <main class="mx-auto max-w-7xl px-6 py-6">
      <StatusColumns />
    </main>
  </div>
</template>
