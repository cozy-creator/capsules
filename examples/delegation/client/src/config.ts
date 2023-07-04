import { Connection, Ed25519Keypair, JsonRpcProvider, RawSigner } from "@mysten/sui.js";

const fullnode = "https://fullnode.testnet.sui.io:443";
const ownerMnemonics = "pause estate bargain cycle grow same trumpet north merge check expire zoo";
const agentMnemonics = "hybrid sniff fan aisle easily seat cycle zoo struggle renew change leave";
const fakeOwnerMnemonics = "train heavy pizza chunk eight march silver seminar gauge unveil brain upset";

export const ownerKeypair = Ed25519Keypair.deriveKeypair(ownerMnemonics);
export const agentKeypair = Ed25519Keypair.deriveKeypair(agentMnemonics);
export const fakeOwnerKeypair = Ed25519Keypair.deriveKeypair(fakeOwnerMnemonics);

export const provider = new JsonRpcProvider(new Connection({ fullnode }));
export const ownerSigner = new RawSigner(ownerKeypair, provider);
export const agentSigner = new RawSigner(agentKeypair, provider);
export const fakeOwnerSigner = new RawSigner(fakeOwnerKeypair, provider);

export const baseGasBudget = 100_000_000;
export const babyPackageId = "0xaacb093dc7c98a79a5441a343fae064ebe6898926c2e07b5922ddae055d9447e";
export const publishReceiptId = "0xf8f1028144184bf2b894fe4ba5327129eb456bf4510c3e4bafbe98e0021ff7fb";
export const ownershipPackageId = "0xdcbadd322069f668204440a6245922a705922e9d1e061543c4bbf388d62d92db";
