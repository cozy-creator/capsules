import { Ed25519Keypair, RawSigner, JsonRpcProvider } from "@mysten/sui.js";

const privateKeyBytes = new Uint8Array([
  132, 54, 122, 250, 165, 129, 138, 9, 27, 139, 141, 26, 251, 132, 105, 197, 222, 13, 99, 214, 58, 249, 145, 34, 191,
  69, 206, 232, 232, 208, 127, 60, 189, 137, 111, 147, 146, 3, 153, 199, 100, 74, 64, 131, 145, 63, 134, 219, 99, 85,
  235, 27, 193, 32, 115, 230, 40, 217, 14, 248, 76, 212, 88, 83,
]);

export const provider = new JsonRpcProvider("https://fullnode.devnet.sui.io:443");
const keypair = Ed25519Keypair.fromSecretKey(privateKeyBytes);
export const signer = new RawSigner(keypair, provider);

export const publicKey = "0xed2c39b73e055240323cf806a7d8fe46ced1cabb";
export const dispenserPackageId = "0xaef57ad95f23b2eb5c0bb8366606fc6888bea329";
export const dispenserObjectId = "0x5a2ffae755c682756c70ea4c5efdd290c49a002e";

export const nftData = [
  {
    name: "SUI NFT #1",
    description: "This is #1 NFT description.",
    url: "ipfs://QmZPWWy5Si54R3d26toaqRiqvCH7HkGdXkxwUgCm2oKKM2?filename=img-sq-01.png",
  },
  {
    name: "SUI NFT #2",
    description: "This is #2 NFT description.",
    url: "ipfs://QmZPWWy5Si54R3d26toaqRiqvCH7HkGdXkxwUgCm2oKKM2?filename=img-sq-01.png",
  },
  {
    name: "SUI NFT #3",
    description: "This is #3 NFT description.",
    url: "ipfs://QmZPWWy5Si54R3d26toaqRiqvCH7HkGdXkxwUgCm2oKKM2?filename=img-sq-01.png",
  },
  {
    name: "SUI NFT #4",
    description: "This is #4 NFT description.",
    url: "ipfs://QmZPWWy5Si54R3d26toaqRiqvCH7HkGdXkxwUgCm2oKKM2?filename=img-sq-01.png",
  },
  {
    name: "SUI NFT #5",
    description: "This is #5 NFT description.",
    url: "ipfs://QmZPWWy5Si54R3d26toaqRiqvCH7HkGdXkxwUgCm2oKKM2?filename=img-sq-01.png",
  },
];
