import { Connection, Ed25519Keypair, JsonRpcProvider, RawSigner } from "@mysten/sui.js";

const fullnode = "http://127.0.0.1:9000";
const ownerMnemonics = "pause estate bargain cycle grow same trumpet north merge check expire zoo";
const merchantMnemonics = "hybrid sniff fan aisle easily seat cycle zoo struggle renew change leave";

export const ownerKeypair = Ed25519Keypair.deriveKeypair(ownerMnemonics);
export const merchantKeypair = Ed25519Keypair.deriveKeypair(merchantMnemonics);

// console.log(ownerKeypair.getPublicKey().toSuiAddress());
// console.log(merchantKeypair.getPublicKey().toSuiAddress());

export const provider = new JsonRpcProvider(new Connection({ fullnode }));
export const ownerSigner = new RawSigner(ownerKeypair, provider);
export const merchantSigner = new RawSigner(merchantKeypair, provider);

export const baseGasBudget = 100_000_000;
export const coinRegistryId = "0x0d211e788157f5e7e46fe7a4b99fb72a42b30ae83fc3ab0f06e8279a7f984b7e";
