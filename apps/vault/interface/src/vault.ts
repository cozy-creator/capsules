import { JsonRpcProvider } from "@mysten/sui.js";

export const provider = new JsonRpcProvider("https://fullnode.testnet.sui.io:443");

export async function getVaults(address: string) {
  const objects = await provider.getObjectsOwnedByAddress(address);

  console.log(objects);
}
