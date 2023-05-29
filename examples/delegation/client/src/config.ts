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
export const babyPackageId = "0x519000a83ffdce37fe0a4a715649e6d02e570ff2a5946f7cd166577138de17fe";
export const publishReceiptId = "0x419287c04b3e5ea2f5b51132c6d0ad3808e4a62d8a9568ca82ec84d0e79f1959";
export const ownershipPackageId = "0x67ddd36c005d4ab7f2b5062143f2c33fa8b88e745a9e5d805dd764a06d7675df";
