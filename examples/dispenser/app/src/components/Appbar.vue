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

    <v-btn variant="flat" color="primary" @click="showConnect">Connect</v-btn>
  </v-app-bar>
</template>

<script lang="ts" setup>
import { ref } from "vue";
import { ethosForVue } from "ethos-connect-vue";
const drawer = ref(null);
const sidelinks = [
  {
    title: "Create Dispenser",
    to: "/dispenser/create",
    icon: "mdi-plus",
  },
  {
    title: "View Dispenser",
    to: "/dispenser/view",
    icon: "mdi-compare",
  },
  {
    title: "My Dispensers",
    to: "/dispensers",
    icon: "mdi-view-list",
  },
];

const ethos = ethosForVue();

function showConnect() {
  ethos.context.modal.openModal();
}
</script>
