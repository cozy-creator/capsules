import { Connection, Ed25519Keypair, JsonRpcProvider, RawSigner, TransactionBlock, bcs } from "@mysten/sui.js";
import { toHEX } from "@mysten/bcs";

const mnemonics = "fault art rose august much prefer current chronic giant dilemma excess portion enact biology simple";
const provider = new JsonRpcProvider(new Connection({ fullnode: "http://127.0.0.1:9000" }));
bcs.registerStructType("Message", { value: "vector<u8>" });

const keypair = Ed25519Keypair.deriveKeypair(mnemonics);
const signer = new RawSigner(keypair, provider);
const packageId = "0xc20155473cc4152ca30333147d8b596aa02915272f638a3af6b7e09fb14318b5";

const message = "Hello world from the outside world";
const publicKeyBytes = keypair.getPublicKey().toBytes();
const messageBytes = bcs.ser("Message", { value: Buffer.from(message) }).toBytes();

console.log(messageBytes);

async function main() {
  const dataSig = await signer.signData(messageBytes);
  const messageSig = await signer.signMessage({ message: messageBytes });

  const txb = new TransactionBlock();
  const publicKeyHex = toHEX(publicKeyBytes);
  const dataSigHex = toHEX(Buffer.from(dataSig, "base64")).slice(0, -64);
  const messageSigHex = toHEX(Buffer.from(messageSig.signature, "base64")).slice(0, -64);

  txb.moveCall({
    arguments: [txb.pure(dataSigHex), txb.pure(publicKeyHex), txb.pure(message)],
    target: `${packageId}::signature::verify`,
    typeArguments: [],
  });

  const resp = await signer.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: {
      showEvents: true,
    },
  });

  // @ts-expect-error
  console.log(resp.events[0]);
}

main();
