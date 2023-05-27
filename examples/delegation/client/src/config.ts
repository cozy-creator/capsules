import { Connection, Ed25519Keypair, JsonRpcProvider, RawSigner } from "@mysten/sui.js";

const ownerMnemonics = "pause estate bargain cycle grow same trumpet north merge check expire zoo";
const agentMnemonics = "hybrid sniff fan aisle easily seat cycle zoo struggle renew change leave";

const ownerKeypair = Ed25519Keypair.deriveKeypair(ownerMnemonics);
const agentKeypair = Ed25519Keypair.deriveKeypair(agentMnemonics);

export const provider = new JsonRpcProvider(new Connection({ fullnode: "http://127.0.0.1:9000" }));
export const ownerSigner = new RawSigner(ownerKeypair, provider);
export const agentSigner = new RawSigner(agentKeypair, provider);

export const babyPackageId = "0xa47f4c1c218585c898588fd3d0282b085280157660a308d88f33c2557b10fa3f";
export const ownershipPackageId = "0x67ddd36c005d4ab7f2b5062143f2c33fa8b88e745a9e5d805dd764a06d7675df";
export const basGasBudget = 100_000_000;
