import App from "./App.vue";
import { createApp } from "vue";
import { registerPlugins } from "@/plugins";
import { EthosConnectPlugin, EthosConfiguration } from "ethos-connect-vue";
import { Chain } from "ethos-connect-vue/dist/enums/Chain";

const app = createApp(App);
const config: EthosConfiguration = {
  disableAutoConnect: true,
  hideEmailSignIn: true,
  chain: "sui:custom" as Chain,
  network: "http://127.0.0.1:9000",
  pollingInterval: 3_600_000,
};

registerPlugins(app);
app.use(EthosConnectPlugin, config).mount("#app");
