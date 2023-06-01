<template>
  <EthosConnectProvider>
    <v-app>
      <Appbar />

      <v-main>
        <v-container>
          <router-view />
        </v-container>
      </v-main>
    </v-app>
  </EthosConnectProvider>
</template>

<script lang="ts" setup>
import Appbar from "@/components/Appbar.vue";
</script>
