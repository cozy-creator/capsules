import { Ed25519Keypair, JsonRpcProvider, RawSigner } from "@mysten/sui.js";

export const publicKey = "0xed2c39b73e055240323cf806a7d8fe46ced1cabb";
export const packageID = "0xad10acb641b8d2581f105c4e6dad061470518468";
export const schemaID = "0x54acc3f4e76cfd3316899f5782acf10b967b730d";
export const objectID = "0x899fb0358b6b85114a6258743d0605eb0fc2c4b2";

const privateKeyBytes = new Uint8Array([
    132, 54, 122, 250, 165, 129, 138, 9, 27, 139, 141, 26, 251, 132, 105, 197, 222, 13, 99, 214, 58,
    249, 145, 34, 191, 69, 206, 232, 232, 208, 127, 60, 189, 137, 111, 147, 146, 3, 153, 199, 100, 74,
    64, 131, 145, 63, 134, 219, 99, 85, 235, 27, 193, 32, 115, 230, 40, 217, 14, 248, 76, 212, 88, 83
  ]);
  
// Build a class to connect to Sui RPC servers
export const provider = new JsonRpcProvider('https://fullnode.testnet.sui.io:443');
  
// Import the above keypair
const keypair = Ed25519Keypair.fromSecretKey(privateKeyBytes);
export const signer = new RawSigner(keypair, provider);

