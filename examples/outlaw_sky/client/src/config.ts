import { Ed25519Keypair, JsonRpcProvider, RawSigner } from "@mysten/sui.js";

// private key (base64 encoded): hDZ6+qWBigkbi40a+4Rpxd4NY9Y6+ZEiv0XO6OjQfzy9iW+TkgOZx2RKQIORP4bbY1XrG8Egc+Yo2Q74TNRYUw==
// public key (hex encoded): 0xed2c39b73e055240323cf806a7d8fe46ced1cabb
const privateKeyBytes = new Uint8Array([
  132, 54, 122, 250, 165, 129, 138, 9, 27, 139, 141, 26, 251, 132, 105, 197, 222, 13, 99, 214, 58, 249, 145, 34, 191,
  69, 206, 232, 232, 208, 127, 60, 189, 137, 111, 147, 146, 3, 153, 199, 100, 74, 64, 131, 145, 63, 134, 219, 99, 85,
  235, 27, 193, 32, 115, 230, 40, 217, 14, 248, 76, 212, 88, 83,
]);

// Build a class to connect to Sui RPC servers
export const provider = new JsonRpcProvider("https://fullnode.devnet.sui.io:443", {
  faucetURL: "https://faucet.devnet.sui.io/gas",
});

// Import the above keypair
const keypair = Ed25519Keypair.fromSecretKey(privateKeyBytes);
export const signer = new RawSigner(keypair, provider);

export const publicKey = "0xed2c39b73e055240323cf806a7d8fe46ced1cabb";
export const outlawSkyPackageID = "0xdf60b06c7daa315b98e11e7a3516b2ead8928ef3";
export const metadataPackageID = "0xe5eefaf7f8e79ed76d9120a8338e7f5106116ba1";
export const schemaObjectID = "0x6bd0af67e5634dca308f4674b9e770bb2b1f0bc6";
export const outlawObjectID = "0x20def772eba38237b331faa2870113f05abbed42";
