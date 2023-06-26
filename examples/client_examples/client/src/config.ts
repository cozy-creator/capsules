import { Connection, Ed25519Keypair, JsonRpcProvider, RawSigner } from "@mysten/sui.js";

const fullnode = "http://127.0.0.1:9000";
const ownerMnemonics = "pause estate bargain cycle grow same trumpet north merge check expire zoo";
const agentMnemonics = "hybrid sniff fan aisle easily seat cycle zoo struggle renew change leave";
const fakeOwnerMnemonics = "train heavy pizza chunk eight march silver seminar gauge unveil brain upset";

export const ownerKeypair = Ed25519Keypair.deriveKeypair(ownerMnemonics);
export const agentKeypair = Ed25519Keypair.deriveKeypair(agentMnemonics);
export const fakeOwnerKeypair = Ed25519Keypair.deriveKeypair(fakeOwnerMnemonics);

// console.log(ownerKeypair.getPublicKey().toSuiAddress());
// console.log(agentKeypair.getPublicKey().toSuiAddress());

export const provider = new JsonRpcProvider(new Connection({ fullnode }));
export const ownerSigner = new RawSigner(ownerKeypair, provider);
export const agentSigner = new RawSigner(agentKeypair, provider);
export const fakeOwnerSigner = new RawSigner(fakeOwnerKeypair, provider);

export const baseGasBudget = 100_000_000;
export const publishReceiptId = "";
