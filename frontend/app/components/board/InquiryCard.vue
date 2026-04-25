<script setup lang="ts">
import type { Inquiry } from '~/types/inquiry'
import { Card, CardContent, CardHeader, CardTitle } from '~/components/ui/card'

defineProps<{
  inquiry: Inquiry
}>()
</script>

<template>
  <Card class="gap-2 py-3">
    <CardHeader class="px-3">
      <CardTitle class="text-sm font-medium leading-snug">
        {{ inquiry.title }}
      </CardTitle>
    </CardHeader>
    <CardContent
      v-if="inquiry.description"
      class="px-3"
    >
      <p class="line-clamp-2 text-xs text-muted-foreground">
        {{ inquiry.description }}
      </p>
    </CardContent>
  </Card>
</template>
