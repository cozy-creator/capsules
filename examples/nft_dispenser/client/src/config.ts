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
export const dispenserPackageId = "0x2ba2b7d263ad5d52c30c394da47827569a7c71d9";
export const dispenserObjectId = "0x419bce82e05065c8302c74703e5d7b9258e1235f";
export const adminCapId = "0x49b8e8bd937e9cfb90c900a3a56e024aae54fef2";

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
