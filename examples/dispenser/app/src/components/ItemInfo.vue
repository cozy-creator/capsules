<template>
  <div class="d-flex">
    <span>{{ text }}:</span>

    <v-spacer />

    <span>{{ value }}</span>
  </div>

  <v-divider v-show="!hideDivider" class="my-3" />
</template>

<script lang="ts" setup>
defineProps<{
  text: string;
  value: string | number | boolean;
  hideDivider?: boolean;
}>();
</script>
