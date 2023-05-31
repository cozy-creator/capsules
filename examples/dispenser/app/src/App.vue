<template>
  <EthosConnectProvider>
    <v-app>
      <Appbar />

      <v-container>
        <v-main>
          <router-view />
        </v-main>
      </v-container>
    </v-app>
  </EthosConnectProvider>
</template>

<script lang="ts" setup>
import Appbar from "@/components/Appbar.vue";
</script>
