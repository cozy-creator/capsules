<template>
  <h2 class="mb-5 text-center">Create Dispenser</h2>

  <v-row>
    <v-col cols="12" md="8" class="mx-auto">
      <v-row>
        <v-col cols="12" md="6">
          <v-label class="mb-2">Start Date</v-label>
          <v-text-field
            density="comfortable"
            hide-details
            type="date"
            variant="outlined"
            color="primary"
            v-model="input.startDate"
          />
        </v-col>

        <v-col cols="12" md="6">
          <v-label class="mb-2">End Date</v-label>
          <v-text-field
            density="comfortable"
            hide-details
            type="date"
            variant="outlined"
            color="primary"
            v-model="input.endDate"
          />
        </v-col>
      </v-row>

      <v-row>
        <v-col cols="12" md="6">
          <v-label class="mb-2">Mint Price</v-label>
          <v-text-field
            density="comfortable"
            hide-details
            type="number"
            variant="outlined"
            color="primary"
            v-model.number="input.price"
          />
        </v-col>

        <v-col cols="12" md="6">
          <v-label class="mb-2">Total Items</v-label>
          <v-text-field
            density="comfortable"
            hide-details
            type="number"
            variant="outlined"
            color="primary"
            v-model.number="input.totalItems"
          />
        </v-col>
      </v-row>

      <div class="my-2">
        <v-label class="mb-2">Items Schema</v-label>
        <v-textarea
          hide-details
          rows="2"
          readonly
          density="comfortable"
          variant="outlined"
          color="primary"
          v-model:model-value="input.schema"
        />
      </div>

      <div class="my-2">
        <v-label class="mb-2">Items Description</v-label>
        <v-textarea
          rows="2"
          hide-details
          density="comfortable"
          variant="outlined"
          color="primary"
          v-model="input.description"
        />
      </div>

      <v-row>
        <v-col cols="12" md="6">
          <v-switch
            v-model="input.isRandom"
            color="primary"
            label="Random Mint"
            inset
          />
        </v-col>
      </v-row>

      <v-btn @click="createDispenser" flat variant="tonal" color="primary" block
        >Create</v-btn
      >
    </v-col>
  </v-row>
</template>

<script lang="ts" setup>
import { reactive } from "vue";

const input = reactive({
  price: 0,
  totalItems: 0,
  endDate: "",
  startDate: "",
  description: "",
  schema: '["String", "String"]',
  isRandom: true,
});

async function createDispenser() {
  const startDate =
    input.startDate == "" ? 0 : new Date(input.startDate).getTime();
  const endDate = input.endDate == "" ? 0 : new Date(input.endDate).getTime();

  const refinedInput = { ...input, startDate, endDate };

  // const dispenserId = await
}
</script>
