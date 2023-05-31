import App from "./App.vue";
import { createApp } from "vue";
import { registerPlugins } from "@/plugins";
import { EthosConnectPlugin, EthosConfiguration } from "ethos-connect-vue";

const app = createApp(App);
const config: EthosConfiguration = {
  disableAutoConnect: true,
  hideEmailSignIn: true,
};

registerPlugins(app);
app.use(EthosConnectPlugin, config).mount("#app");
