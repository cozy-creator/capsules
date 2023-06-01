<template>
  <!-- <p>
      https://axkdkd.com/rec

      <v-btn flat icon="mdi-content-copy" size="small" density="compact" />
    </p> -->

  <v-row v-if="!data.loading">
    <template v-if="!data.dispenserId">
      <v-col cols="12" md="6">
        <div class="mb-5">
          <h2>View Dispenser</h2>
        </div>

        <DispenserInput
          button-label="Fetch dispenser"
          @submit="fetchDispenser"
        />
      </v-col>
    </template>

    <template v-else>
      <v-col cols="12" md="5">
        <div class="mb-5">
          <h2>
            Dispenser
            {{ truncateEthAddress(data.dispenserId) }}
          </h2>
        </div>
        <div>
          <h4 class="mb-3">Dispenser Details</h4>

          <ItemInfo
            text="Mint Price"
            :value="`${
              data.dispenser?.coinMetadata
                ? data.dispenser?.price +
                  ' ' +
                  data.dispenser?.coinMetadata?.symbol
                : 'Free'
            }`"
          />
          <ItemInfo
            text="Dispenser Balance"
            :value="`${
              data.dispenser?.coinMetadata
                ? data.dispenser?.balance +
                  ' ' +
                  data.dispenser?.coinMetadata?.symbol
                : 'N/A'
            }`"
          />
          <ItemInfo text="Total Items" :value="data.dispenser?.totalItems!" />
          <ItemInfo
            text="Items Minted"
            :value="data.dispenser?.itemsLoaded! - data.dispenser?.itemSize!"
          />
          <ItemInfo
            text="Start Date"
            :value="data.dispenser?.startTime == 0 ? 'N/A': new Date(data.dispenser?.startTime!).toDateString()"
          />
          <ItemInfo
            hide-divider
            text="End Date"
            :value="data.dispenser?.endTime == 0 ? 'N/A': new Date(data.dispenser?.endTime!).toDateString()"
          />
        </div>

        <v-divider class="mb-5 mt-10" />
        <!-- <div>
        <div class="d-flex">
          <h4 class="mb-3">Withdraw Coin</h4>
          <v-spacer />
          <p>{{data.dispenser?.balance}} ${data.dispenser?.coinMetadata && data.dispenser.coinMetadata.symbol}</p>
        </div>

        <v-text-field
          color="primary"
          density="comfortable"
          variant="outlined"
          type="number"
        />
        <v-btn color="primary" variant="tonal" flat block>Withdraw</v-btn>
      </div> -->
      </v-col>

      <v-col cols="12" md="7">
        <LoadDispenser @load-dispenser="loadDispenser" />
      </v-col>
    </template>
  </v-row>
</template>

<script lang="ts" setup>
import {
  getDispenser,
  DispenserValueType,
  executeLoadDispenserItems,
} from "@/utils/dispenser";
import { truncateEthAddress } from "@/utils/utils";
import { reactive } from "vue";
import { onMounted } from "vue";
import { useRoute } from "vue-router";
import { ethosForVue } from "ethos-connect-vue";
import ItemInfo from "@/components/ItemInfo.vue";
import LoadDispenser from "@/components/LoadDispenser.vue";
import DispenserInput from "@/components/DispenserInput.vue";

const {
  context: {
    providerAndSigner: { signer },
  },
} = ethosForVue();
const route = useRoute();
const data: {
  loading: boolean;
  dispenser?: DispenserValueType;
  loadDispenser: { file: File[] };
  dispenserId?: string;
} = reactive({
  loading: false,
  loadDispenser: { file: [] },
});

onMounted(async () => {
  await fetchDispenser(<string>route.query.id);
});

async function fetchDispenser(id: string) {
  try {
    data.loading = true;
    data.dispenser = await getDispenser(id);
    data.dispenserId = id;
  } catch (e) {
    console.log(e);
  } finally {
    data.loading = false;
  }
}

// Currently written for small files (large files might crash the browsee)
async function loadDispenser(file?: File) {
  if (!file) throw new Error("File not selected");
  if (file.type != "application/json") throw new Error("File must be JSON");

  const content = JSON.parse(await file.text());
  await executeLoadDispenserItems(
    {
      items: content,
      coinType: data.dispenser?.coinType!,
      dispenserId: data.dispenserId!,
    },
    { signer }
  );
}
</script>
