<template>
  <v-navigation-drawer v-model="drawer">
    <v-list-item prepend-avatar="/assets/logo.svg" title="Capsules Dispenser" />

    <v-divider></v-divider>

    <v-list density="comfortable" nav>
      <template v-for="link in sidelinks">
        <v-list-item
          ripple
          rounded
          :prepend-icon="link.icon"
          :title="link.title"
          :to="link.to"
        />
      </template>
    </v-list>
  </v-navigation-drawer>

  <v-app-bar flat>
    <v-app-bar-nav-icon @click="drawer = !drawer" />
    <v-spacer />

    <v-btn
      v-if="ethos.context.wallet.status != 'connected'"
      variant="tonal"
      color="black"
      @click="showConnect"
    >
      Connect wallet
    </v-btn>
    <v-btn v-else variant="tonal" color="primary" @click="disconnect">
      Connected:
      {{ truncateEthAddress(ethos.context.wallet.wallet?.address) }}
    </v-btn>
  </v-app-bar>
</template>

<script lang="ts" setup>
import { ref } from "vue";
import { ethosForVue } from "ethos-connect-vue";
import { truncateEthAddress } from "@/utils/utils";
import { useRouter } from "vue-router";

const drawer = ref(null);
const router = useRouter();
const ethos = ethosForVue();

const sidelinks = [
  {
    title: "Create Dispenser",
    icon: "mdi-plus-circle",
    to: "/dispenser/create",
  },
  {
    title: "Dispenser info",
    icon: "mdi-information",
    to: "/dispenser/view",
  },
];

console.log(ethos);
function showConnect() {
  ethos.context.modal.openModal();
}

function disconnect() {
  ethos.context.wallet.wallet.disconnect();
}
</script>
