import { Connection, JsonRpcProvider } from "@mysten/sui.js";

export function truncateEthAddress(address: string = "") {
  const prefix = address.substring(0, 5);
  const suffix = address.substring(address.length - 5);

  return prefix + "..." + suffix;
}

export async function getCoinMetataData(coinType: string) {
  const provider = new JsonRpcProvider(
    new Connection({ fullnode: "http://127.0.0.1:9000" })
  );

  return await provider.getCoinMetadata({ coinType });
}
