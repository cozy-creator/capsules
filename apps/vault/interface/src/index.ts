import { Connection } from "./connection";
import { App } from "./modules/App";
import { getVaults } from "./vault";

const packageId = "0xfd4c6285a2b092c8ec7fa3f780a43c5a40a96e5c";

const root = document.querySelector("#root");

const connection = new Connection();

window.addEventListener("load", async () => {
  connection.init();
  const context = {
    wallets: connection.wallets,
    account: connection.currentAccount,
    isConnected: connection.state.isConnected,
  };

  root.innerHTML = App(context);

  const wallets = connection.wallets.map((wallet) => wallet.name);
  wallets.forEach((wallet) => {
    document
      .querySelector(`#${wallet.replaceAll(" ", "-")}`)
      .addEventListener("click", () => connection.connect(wallet));
  });

  //   const vaults = await getVaults("0x9c51d10c0d1846e85570773836a3508d1ab91378");
  //   console.log(vaults);
});
