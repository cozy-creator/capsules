import { Connection, JsonRpcProvider, TransactionBlock, bcs } from "@mysten/sui.js";

// Setup connection
const connection = new Connection({ fullnode: "https://fullnode.testnet.sui.io:443" });
const provider = new JsonRpcProvider(connection);

// register our `String` struct type and `UID` alias
bcs.registerStructType("String", { bytes: "vector<u8>" });
bcs.registerAlias("UID", "address");

const sender = "0x082d360c6133f27eddf5051fc9afe26be8aa45e9edda9280b70c82d33c334053";
const packageId = "0xed93ad8d8904df8c0008949ca8572c1bdbd2fbc21efcb8c425ef2253eac82c6e";

async function getUndefinedField(objectId: string) {
  const txb = new TransactionBlock();

  const uid = txb.pure(bcs.ser("UID", objectId).toBytes());
  const key = txb.pure(bcs.ser("vector<u8>", Buffer.from("somerandomfield")).toBytes());
  const type = txb.pure(bcs.ser("String", { bytes: Buffer.from("String") }).toBytes());

  txb.moveCall({
    target: `${packageId}::serializer::get_bcs_bytes`,
    arguments: [uid, key, type],
    typeArguments: ["0x1::string::String"],
  });

  const response = await provider.devInspectTransactionBlock({ transactionBlock: txb, sender });

  // This currently errors, so we print the error
  console.log(response.error);
}

async function tryUnrecognizedType(objectId: string) {
  const txb = new TransactionBlock();

  const uid = txb.pure(bcs.ser("UID", objectId).toBytes());
  const key = txb.pure(bcs.ser("vector<u8>", Buffer.from("name")).toBytes());

  // serialize an unrecognized type `Array`
  const type = txb.pure(bcs.ser("String", { bytes: Buffer.from("Array") }).toBytes());

  txb.moveCall({
    target: `${packageId}::serializer::get_bcs_bytes`,
    arguments: [uid, key, type],
    typeArguments: ["vector<u8>"],
  });

  const response = await provider.devInspectTransactionBlock({ transactionBlock: txb, sender });

  // This currently errors, so we print the error
  console.log(response.error);
}

const objectId = "0x03c5a4b2717f1f205857059661f8e9a2a1ef91e838fa630cf5b68d14a29bdbae";
getUndefinedField(objectId);
// tryUnrecognizedType(objectId);
