import { Connection } from "./connection";
import { App } from "./modules/App";

const packageId = "0xfd4c6285a2b092c8ec7fa3f780a43c5a40a96e5c";

window.addEventListener("load", async () => {
  const connection = new Connection();
  connection.init();

  const context = {
    wallets: connection.wallets,
    account: window.localStorage.getItem("account"),
    isConnected: !!window.localStorage.getItem("isConnected")
      ? JSON.parse(window.localStorage.getItem("isConnected"))
      : false,
  };

  const root = document.querySelector("#root");
  root.innerHTML = App(context);

  setupWalletConnectListeners(connection);
  setupWalletDisconnectListener(connection);
});

function setupWalletConnectListeners(connection: Connection) {
  const walletNames = connection.wallets.map((wallet) => wallet.name);

  walletNames.forEach((walletName) => {
    document.querySelector(`#${walletName.replace(/ /g, "")}`).addEventListener("click", async () => {
      await connection.connect(walletName);

      window.localStorage.setItem("account", connection.currentAccount);
      window.localStorage.setItem("isConnected", "true");

      window.location.reload();
    });
  });
}

function setupWalletDisconnectListener(connection: Connection) {
  const disconnectBtn = document.querySelector("#disconnectBtn");

  disconnectBtn.addEventListener("click", async () => {
    await connection.disconnect();

    window.localStorage.removeItem("account");
    window.localStorage.removeItem("isConnected");

    window.location.reload();
  });
}
