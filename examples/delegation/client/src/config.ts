import { Connection, Ed25519Keypair, JsonRpcProvider, RawSigner } from "@mysten/sui.js";

const ownerMnemonics = "pause estate bargain cycle grow same trumpet north merge check expire zoo";
const agentMnemonics = "hybrid sniff fan aisle easily seat cycle zoo struggle renew change leave";
const fakeOwnerMnemonics = "train heavy pizza chunk eight march silver seminar gauge unveil brain upset";

export const ownerKeypair = Ed25519Keypair.deriveKeypair(ownerMnemonics);
export const agentKeypair = Ed25519Keypair.deriveKeypair(agentMnemonics);
export const fakeOwnerKeypair = Ed25519Keypair.deriveKeypair(fakeOwnerMnemonics);

export const provider = new JsonRpcProvider(new Connection({ fullnode: "http://127.0.0.1:9000" }));
export const ownerSigner = new RawSigner(ownerKeypair, provider);
export const agentSigner = new RawSigner(agentKeypair, provider);
export const fakeOwnerSigner = new RawSigner(fakeOwnerKeypair, provider);

export const baseGasBudget = 100_000_000;
export const babyPackageId = "0x290a3f883aff31ab8b3f0b0bffaa85b21a5ca74a046b7afb78ae67e670bac382";
export const publishReceiptId = "0xe042ce69a00a41cc246e8b2fca5bdcc80d544da089c113837a42291c99ed051a";
export const ownershipPackageId = "0x67ddd36c005d4ab7f2b5062143f2c33fa8b88e745a9e5d805dd764a06d7675df";
