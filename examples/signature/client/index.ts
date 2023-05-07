import { Connection, JsonRpcProvider, Ed25519Keypair, RawSigner, TransactionBlock, MIST_PER_SUI } from "@mysten/sui.js";

// Setup connection
const connection = new Connection({ fullnode: "http://127.0.0.1:9000" });
const provider = new JsonRpcProvider(connection);

const mnemonics = "invest half dress clay green task scare hood quiz good glory angry";
const keypair = Ed25519Keypair.deriveKeypair(mnemonics);
const signer = new RawSigner(keypair, provider);

const packageId = "0x37c782dc931e09f5dd6d58e49bcdcec831da5c2e7bf16f7970be3a074d0678b0";

async function main() {
  const txb = new TransactionBlock();

  const message = "Hey There! I'm signing this...";
  //   const signature = await signer.signMessage({ message: Buffer.from(message) });
  const signature = await signer.signData(Buffer.from(message));

  const pM = Array.from(Buffer.from(Buffer.from(message).toString("hex"), "hex"));
  const pSig = Array.from(Buffer.from(Buffer.from(signature, "base64").toString("hex")).slice(2).slice(0, 64));
  const pk = Array.from(Buffer.from(Buffer.from(keypair.getPublicKey().toString(), "base64").toString("hex")));

  console.log(Buffer.from(pSig).toString("hex"));

  txb.moveCall({
    typeArguments: [],
    arguments: [txb.pure(pSig), txb.pure(pk), txb.pure(pM)],
    target: `${packageId}::signature::verify`,
  });

  const response = await signer.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: { showEvents: true },
  });

  // @ts-expect-error
  console.log(response.events[0].parsedJson);
}

main();
