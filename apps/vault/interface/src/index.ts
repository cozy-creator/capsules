import { Connection } from "./connection";
import { App } from "./modules/App";
import { MoveCallTransaction } from "@mysten/sui.js";

const packageId = "0x7ad32e2b6d7d664a569e9dc742317e71fb83ec40";

window.addEventListener("load", async () => {
  const connection = new Connection();
  connection.init();

  const context = getContext(connection);
  if (context.isConnected) {
    await connection.sync(context.connectedWallet);
  }

  document.querySelector("#root").innerHTML = App(context);

  setupWalletConnectListeners(connection);
  setupWalletDisconnectListener(connection);
  setupCreateVaultButtonListener(connection);
});

function getContext(connection: Connection) {
  const localConnection = window.localStorage.getItem("connection")
    ? JSON.parse(window.localStorage.getItem("connection"))
    : null;

  return {
    wallets: connection.wallets,
    account: localConnection.account,
    connectedWallet: localConnection.walletName,
    isConnected: !!localConnection.isConnected ? JSON.parse(localConnection.isConnected) : false,
  };
}

function setupWalletConnectListeners(connection: Connection) {
  const walletNames = connection.wallets.map((wallet) => wallet.name);

  walletNames.forEach((walletName) => {
    document.querySelector(`#${walletName.replace(/ /g, "")}`).addEventListener("click", async () => {
      await connection.connect(walletName);

      window.localStorage.setItem(
        "connection",
        JSON.stringify({
          account: connection.currentAccount,
          isConnected: true,
          walletName,
        })
      );

      await connection.sync(walletName, true);
    });
  });
}

function setupWalletDisconnectListener(connection: Connection) {
  const disconnectBtn = document.querySelector("#disconnectBtn");

  disconnectBtn?.addEventListener("click", async () => {
    await connection.disconnect();

    window.localStorage.setItem(
      "connection",
      JSON.stringify({
        account: "",
        isConnected: false,
        walletName: "",
      })
    );

    window.location.reload();
  });
}

function setupCreateVaultButtonListener(connection: Connection) {
  const createVaultBtn = document.querySelector("#createVaultBtn");

  createVaultBtn?.addEventListener("click", async () => {
    try {
      const moveCallArgs: MoveCallTransaction = {
        arguments: [],
        typeArguments: [],
        function: "create_vault",
        module: "vault",
        packageObjectId: packageId,
        gasBudget: 30000,
      };

      await connection.executeMoveCall(moveCallArgs);
    } catch (e) {
      console.log(e);
    }
  });
}
