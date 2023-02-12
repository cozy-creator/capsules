import { createWalletKitCore, WalletKitCore } from "@mysten/wallet-kit-core";
import { WalletStandardAdapterProvider } from "@mysten/wallet-adapter-wallet-standard";
import {
  ExecuteTransactionRequestType,
  MoveCallTransaction,
  SignableTransaction,
  SuiExecuteTransactionResponse,
} from "@mysten/sui.js";

export class Connection {
  private _walletKit: WalletKitCore;

  init() {
    this._walletKit = createWalletKitCore({ adapters: new WalletStandardAdapterProvider().get() });
  }

  async connect(walletName: string) {
    return await this._walletKit.connect(walletName);
  }

  async disconnect() {
    return await this._walletKit.disconnect();
  }

  async executeMoveCall(
    transaction: MoveCallTransaction,
    requestType: ExecuteTransactionRequestType = "WaitForLocalExecution"
  ) {
    return await this._walletKit.signAndExecuteTransaction({ kind: "moveCall", data: transaction }, { requestType });
  }

  get state() {
    return this._walletKit.getState();
  }

  get currentAccount() {
    return this.state.currentAccount;
  }

  get wallets() {
    return this.state.wallets.map((w) => ({ name: w.name, icon: w.icon }));
  }

  async sync(walletName: string, reload?: boolean) {
    if (reload) window.location.reload();
    await this.connect(walletName);
  }
}
