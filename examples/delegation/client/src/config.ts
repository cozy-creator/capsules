import { Connection, Ed25519Keypair, JsonRpcProvider, RawSigner } from "@mysten/sui.js";

const ownerMnemonics = "pause estate bargain cycle grow same trumpet north merge check expire zoo";
const agentMnemonics = "hybrid sniff fan aisle easily seat cycle zoo struggle renew change leave";

export const ownerKeypair = Ed25519Keypair.deriveKeypair(ownerMnemonics);
export const agentKeypair = Ed25519Keypair.deriveKeypair(agentMnemonics);

export const provider = new JsonRpcProvider(new Connection({ fullnode: "http://127.0.0.1:9000" }));
export const ownerSigner = new RawSigner(ownerKeypair, provider);
export const agentSigner = new RawSigner(agentKeypair, provider);

export const basGasBudget = 100_000_000;
export const babyPackageId = "0xd8323074a866156aaec301d447a90b0ae0322555828ab36deeb3b8e9f1cc1bab";
export const publishReceiptId = "0x0c016d00fea437e4b119f7a8cd162abaf55a7c1d21e447d6466748308b151fdf";
export const ownershipPackageId = "0x67ddd36c005d4ab7f2b5062143f2c33fa8b88e745a9e5d805dd764a06d7675df";
