<template>
  <v-label class="mb-2">Dispenser ID</v-label>
  <v-text-field
    v-model="input.dispenserId"
    density="comfortable"
    variant="outlined"
    color="primary"
    type="text"
    @input="$emit('input', input.dispenserId)"
  />

  <v-btn
    @click="$emit('submit', input.dispenserId)"
    color="primary"
    variant="tonal"
    block
    flat
  >
    {{ buttonLabel }}
  </v-btn>
</template>

<script lang="ts" setup>
import { onMounted } from "vue";
import { reactive } from "vue";

const input = reactive({ dispenserId: "" });
const props = defineProps<{ buttonLabel: string; defaultValue?: string }>();
onMounted(() => {
  input.dispenserId = props.defaultValue || "";
});
</script>
