import { Connection, Ed25519Keypair, JsonRpcProvider, RawSigner, TransactionBlock } from "@mysten/sui.js";
import { serializeByField, bcs, deserializeByField } from "@capsulecraft/serializer";

const pkg = "0x770f088a0fcc7da37a631aaf9af59c0ffa935064171bd0e8dccfdab8f0c77150";
const mnemonics = "...";

// Setup connection
const connection = new Connection({ fullnode: "http://127.0.0.1:9000" });
const provider = new JsonRpcProvider(connection);

const keypair = Ed25519Keypair.deriveKeypair(mnemonics);
const signer = new RawSigner(keypair, provider);

interface SerializeFieldOpts {
  objectId: string;
  field: Uint8Array;
  value: Uint8Array;
}

interface RemoveFieldOpts {
  objectId: string;
  field: Uint8Array;
}

interface SerializeFieldsOpts {
  objectId: string;
  fields: Uint8Array[];
  values: Uint8Array[];
}

interface DeserializeFieldsOpts {
  objectId: string;
  schema: Record<string, string>;
}

// register our `String` struct type and `UID` alias
bcs.registerAlias("UID", "address");

async function createObject() {
  const txb = new TransactionBlock();

  txb.moveCall({
    typeArguments: [],
    arguments: [],
    target: `${pkg}::attach::create_object`,
  });

  const response = await signer.signAndExecuteTransactionBlock({ transactionBlock: txb });
  return { digest: response.digest };
}

async function setField(opts: SerializeFieldOpts) {
  const txb = new TransactionBlock();

  txb.moveCall({
    arguments: [txb.object(opts.objectId), txb.pure(opts.field), txb.pure(opts.value)],
    target: `${pkg}::attach::set_field`,
    typeArguments: [],
  });
  txb.setGasBudget(100000000);

  const response = await signer.signAndExecuteTransactionBlock({ transactionBlock: txb });
  return { digest: response.digest };
}

async function removeField(opts: RemoveFieldOpts) {
  const txb = new TransactionBlock();

  txb.moveCall({
    arguments: [txb.object(opts.objectId), txb.pure(opts.field)],
    target: `${pkg}::attach::remove_field`,
    typeArguments: [],
  });
  txb.setGasBudget(100000000);

  const response = await signer.signAndExecuteTransactionBlock({ transactionBlock: txb });
  return { digest: response.digest };
}

async function setFields(opts: SerializeFieldsOpts) {
  if (opts.fields.length !== opts.values.length) throw new Error("Fields and Values length must be the same");

  const txb = new TransactionBlock();
  const obj = txb.object(opts.objectId);

  for (let i = 0; i < opts.fields.length; i++) {
    const field = opts.fields[i];
    const value = opts.values[i];

    txb.moveCall({
      arguments: [obj, txb.pure(field), txb.pure(value)],
      target: `${pkg}::attach::set_field`,
      typeArguments: [],
    });
  }

  txb.setGasBudget(100000000);

  const response = await signer.signAndExecuteTransactionBlock({ transactionBlock: txb });
  return { digest: response.digest };
}

async function deserializeFields(opts: DeserializeFieldsOpts) {
  const txb = new TransactionBlock();
  const uid = txb.pure(bcs.ser("UID", opts.objectId).toBytes());
  const fields = Object.keys(opts.schema).map((key) => key);

  txb.moveCall({
    arguments: [uid, txb.pure(fields)],
    typeArguments: [],
    target: `${pkg}::attach::view_parsed`,
  });

  const response = await provider.devInspectTransactionBlock({ transactionBlock: txb, sender: pkg });

  if (response.error) {
    throw new Error(response.error);
  }

  // @ts-expect-error
  const result = response.results[0].returnValues[0][0];
  const values = bcs.de("vector<vector<u8>>", Uint8Array.from(result));

  return deserializeByField(bcs, values, opts.schema);
}

async function main() {
  const schema = { name: "String", about: "String" };
  const data = { name: "Rahman", about: "Trying to be a better person" };
  const objectId = "0x3011aec6a7e199df723f7139dc37932a07ffe88e09502e4bc70babd103c1d9c2";

  const values = serializeByField(bcs, data, schema);
  const fields = Object.keys(schema).map((key) => bcs.ser("String", key).toBytes());

  // set fields
  await setFields({ objectId, fields, values });

  // retrieve and deserialize fields
  const deserialized1 = await deserializeFields({ objectId, schema });
  console.log(deserialized1);

  // delete field
  await removeField({ objectId, field: fields[0] });

  // retrieve and deserialize fields (excluding deleted field)
  const deserialized2 = await deserializeFields({ objectId, schema: { about: "String" } });
  console.log(deserialized2);
}

main().then(console.log);
