import {
  Connection,
  Ed25519Keypair,
  JsonRpcProvider,
  RawSigner,
} from "@mysten/sui.js";

const fullnode = "http://127.0.0.1:9000";
const ownerMnemonics =
  "pause estate bargain cycle grow same trumpet north merge check expire zoo";
const merchantMnemonics =
  "hybrid sniff fan aisle easily seat cycle zoo struggle renew change leave";

export const ownerKeypair = Ed25519Keypair.deriveKeypair(ownerMnemonics);
export const merchantKeypair = Ed25519Keypair.deriveKeypair(merchantMnemonics);

// console.log(ownerKeypair.getPublicKey().toSuiAddress());
// console.log(merchantKeypair.getPublicKey().toSuiAddress());

export const provider = new JsonRpcProvider(new Connection({ fullnode }));
export const ownerSigner = new RawSigner(ownerKeypair, provider);
export const merchantSigner = new RawSigner(merchantKeypair, provider);

export const baseGasBudget = 100_000_000;
export const coinRegistryId =
  "0xf389822218867c10cb0237c05574d22041d00e69dec8d1c76194093a14e1cb3b";
