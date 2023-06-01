<template>
  <v-row>
    <v-col cols="12" md="8" lg="6" class="mx-auto">
      <h2 class="mb-5">Create Dispenser</h2>

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
            :readonly="input.isFree"
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
        <v-label class="mb-2">Coin Type</v-label>
        <v-text-field
          hide-details
          :readonly="input.isFree"
          density="comfortable"
          variant="outlined"
          color="primary"
          v-model:model-value="input.coinType"
        />
      </div>

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

      <v-row>
        <v-col cols="12" md="6">
          <v-switch
            hide-details
            v-model="input.isRandom"
            color="primary"
            label="Random Mint"
            inset
          />
        </v-col>

        <v-col cols="12" md="6">
          <v-switch
            hide-details
            v-model="input.isFree"
            color="primary"
            label="Free Mint"
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
import { executeCreateDispenser } from "@/utils/dispenser";
import { MIST_PER_SUI } from "@mysten/sui.js";
import { ethosForVue } from "ethos-connect-vue";
import { reactive } from "vue";
import { useRouter } from "vue-router";

const {
  context: {
    providerAndSigner: { signer },
  },
} = ethosForVue();
const router = useRouter();
const input = reactive({
  price: 0,
  totalItems: 0,
  endDate: "",
  startDate: "",
  isFree: false,
  isRandom: true,
  coinType: "0x2::sui::SUI",
  schema: '["String", "String"]',
});

async function createDispenser() {
  const startDate =
    input.startDate == "" ? 0 : new Date(input.startDate).getTime();
  const endDate = input.endDate == "" ? 0 : new Date(input.endDate).getTime();
  const price = BigInt(input.price * Number(MIST_PER_SUI));
  const coinType =
    input.isFree || input.coinType == "" ? undefined : input.coinType;

  const refinedInput = {
    ...input,
    price,
    endDate,
    startDate,
    coinType,
    owner: signer.currentAccount.address,
  };

  const dispenserId = await executeCreateDispenser(refinedInput, { signer });
  router.push({ path: "/dispenser/view", query: { id: dispenserId } });
}
</script>
