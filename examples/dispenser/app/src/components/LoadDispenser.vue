<template>
  <div class="d-flex">
    <h4 class="mb-3">Load Dispenser</h4>

    <v-spacer />

    <router-link to="/">
      <v-icon icon="mdi-download" />
      sample
    </router-link>
  </div>

  <v-sheet style="font-size: 14px" class="pa-3" color="plaster">
    <p class="mb-3">File format:</p>
    <pre>{{ exampleJson }}</pre>
  </v-sheet>

  <div class="mt-3">
    <v-file-input
      v-model="input.file"
      prepend-icon="mdi-file-upload"
      density="comfortable"
      label="Select File"
      variant="outlined"
      color="primary"
      show-size
    />

    <v-btn
      @click="$emit('loadDispenser', input.file[0])"
      color="primary"
      variant="tonal"
      block
      flat
    >
      Load Dispenser
    </v-btn>
  </div>
</template>

<script lang="ts" setup>
import { reactive } from "vue";

const input = reactive({ file: [] });

const exampleJson = `[{
    name: "Item #0001"
    url: "https://someurl.com/1.png",
},
{
    name: "Item #0002"
    url: "https://someurl.com/2.png",
}]`;
</script>
