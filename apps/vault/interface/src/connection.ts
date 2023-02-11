import { createWalletKitCore, WalletKitCore } from "@mysten/wallet-kit-core";
import { WalletStandardAdapterProvider } from "@mysten/wallet-adapter-wallet-standard";

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

  get state() {
    return this._walletKit.getState();
  }

  get currentAccount() {
    return this.state.currentAccount;
  }

  get wallets() {
    return this.state.wallets.map((w) => ({ name: w.name, icon: w.icon }));
  }
}
