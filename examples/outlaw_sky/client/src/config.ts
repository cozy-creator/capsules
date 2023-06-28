import { Connection, Ed25519Keypair, JsonRpcProvider, RawSigner } from "@mysten/sui.js"
import dotenv from "dotenv"
dotenv.config()

export const adminKeypair = Ed25519Keypair.deriveKeypair(<string>process.env.ADMIN_MNEMONICS)
export const fakeAgent = Ed25519Keypair.deriveKeypair(<string>process.env.OWNER_MNEMONICS)
export const agentKeypair = Ed25519Keypair.deriveKeypair(<string>process.env.AGENT_MNEMONICS)

// console.log(adminKeypair.getPublicKey().toSuiAddress());
// console.log(fakeAgent.getPublicKey().toSuiAddress());
// console.log(agentKeypair.getPublicKey().toSuiAddress());

export const provider = new JsonRpcProvider(
    new Connection({
        fullnode: <string>process.env.FULLNODE_URL,
    })
)

export const adminSigner = new RawSigner(adminKeypair, provider)
export const fakeAgentSigner = new RawSigner(fakeAgent, provider)
export const agentSigner = new RawSigner(agentKeypair, provider)

export const baseGasBudget = 10_000_000
export const publishReceiptId = <string>process.env.PUBLISH_RECEIPT
