import { Connection, Ed25519Keypair, JsonRpcProvider, RawSigner } from "@mysten/sui.js";

export const adminKeypair = Ed25519Keypair.deriveKeypair(process.env.ADMIN_MNEMONICS!);
export const ownerKeypair = Ed25519Keypair.deriveKeypair(process.env.OWNER_MNEMONICS!);
export const agentKeypair = Ed25519Keypair.deriveKeypair(process.env.AGENT_MNEMONICS!);

// console.log(adminKeypair.getPublicKey().toSuiAddress());
// console.log(ownerKeypair.getPublicKey().toSuiAddress());
// console.log(agentKeypair.getPublicKey().toSuiAddress());

export const provider = new JsonRpcProvider(
  new Connection({
    fullnode: process.env.FULLNODE_URL!,
  })
);

export const ownerSigner = new RawSigner(ownerKeypair, provider);
export const agentSigner = new RawSigner(agentKeypair, provider);
export const adminSigner = new RawSigner(adminKeypair, provider);

export const baseGasBudget = 10_000_000;
export const publishReceiptId = "";
