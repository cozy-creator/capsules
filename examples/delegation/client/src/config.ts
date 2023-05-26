import { Connection, Ed25519Keypair, JsonRpcProvider, RawSigner } from "@mysten/sui.js";

const ownerMnemonics = "pause estate bargain cycle grow same trumpet north merge check expire zoo";
const agentMnemonics = "hybrid sniff fan aisle easily seat cycle zoo struggle renew change leave";

const ownerKeypair = Ed25519Keypair.deriveKeypair(ownerMnemonics);
const agentKeypair = Ed25519Keypair.deriveKeypair(agentMnemonics);

const provider = new JsonRpcProvider(new Connection({ fullnode: "http://127.0.0.1:9000" }));
export const ownerSigner = new RawSigner(ownerKeypair, provider);
export const agentSigner = new RawSigner(agentKeypair, provider);

export const packageId = "0x7e2d38b649f33111ad51ae318ac03e7626716dbbfff48eacddcec8687f7ff813";
