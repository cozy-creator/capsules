import { Connection, Ed25519Keypair, JsonRpcProvider, RawSigner } from "@mysten/sui.js";

const ownerMnemonics = "pause estate bargain cycle grow same trumpet north merge check expire zoo";
const agentMnemonics = "hybrid sniff fan aisle easily seat cycle zoo struggle renew change leave";

export const ownerKeypair = Ed25519Keypair.deriveKeypair(ownerMnemonics);
export const agentKeypair = Ed25519Keypair.deriveKeypair(agentMnemonics);

export const provider = new JsonRpcProvider(new Connection({ fullnode: "http://127.0.0.1:9000" }));
export const ownerSigner = new RawSigner(ownerKeypair, provider);
export const agentSigner = new RawSigner(agentKeypair, provider);

export const baseGasBudget = 100_000_000;
export const babyPackageId = "0x91231246a8243011cc8fe76bc0bfccd11c080f982e96011d18ce59f12620db8e";
export const publishReceiptId = "0x2b45d6129cb589acd89e9bc56e6784274c0dba00f23f7a3bbeb87486a31dd67f";
export const ownershipPackageId = "0x67ddd36c005d4ab7f2b5062143f2c33fa8b88e745a9e5d805dd764a06d7675df";
