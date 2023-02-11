interface Context {
  wallets: {
    name: string;
    icon: string;
  }[];
  account?: string;
  isConnected: boolean;
}
