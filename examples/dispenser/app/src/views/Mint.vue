<template>
  <v-row>
    <v-col cols="12" md="6">
      <DispenserInput
        :default-value="(route.query.id as string)"
        @input="fetchDispenser"
        @submit="mintItem"
        button-label="Mint item"
      />

      <div class="my-3">
        <p class="mb-1">
          Mint price:
          {{
            data.dispenser?.coinMetadata
              ? data.dispenser?.price +
                " " +
                data.dispenser?.coinMetadata?.symbol
              : "Free"
          }}
        </p>

        <p>Remaining Items: {{ data.dispenser?.itemSize || "N/A" }}</p>
      </div>
    </v-col>

    <v-col cols="12" md="6">
      <template v-if="data.mintedNft">
        <div class="mb-3">
          <h1>{{ data.mintedNft.name }}</h1>
          <p>
            <v-btn
              flat
              density="compact"
              class="pa-0"
              target="_blank"
              :href="`https://explorer.sui.io/object/${data.mintedNft.id}`"
            >
              &rarr; view on explorer
            </v-btn>
          </p>
        </div>
        <v-img :src="data.mintedNft.url" />
      </template>
    </v-col>
  </v-row>
</template>

<script lang="ts" setup>
import DispenserInput from "@/components/DispenserInput.vue";
import {
  getDispenser,
  DispenserValueType,
  dispenseItem,
  NFT,
} from "@/utils/dispenser";
import { onMounted, reactive } from "vue";
import { useRoute } from "vue-router";
import { ethosForVue } from "ethos-connect-vue";

const {
  context: {
    providerAndSigner: { signer },
  },
} = ethosForVue();

const route = useRoute();
const data: {
  loading: boolean;
  dispenser?: DispenserValueType;
  mintedNft?: NFT;
} = reactive({
  loading: false,
});

onMounted(async () => {
  await fetchDispenser(<string>route.query.id);
});

async function fetchDispenser(id: string) {
  try {
    data.loading = true;
    data.dispenser = await getDispenser(id);
  } catch (e) {
    console.log(e);
  } finally {
    data.loading = false;
  }
}

async function mintItem(id: string) {
  data.mintedNft = await dispenseItem({ dispenserId: id }, { signer });
  await fetchDispenser(id);
}
</script>
