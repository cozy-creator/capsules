import { Connection, Ed25519Keypair, JsonRpcProvider, RawSigner, TransactionBlock } from "@mysten/sui.js";
import { serializeByField, bcs, deserializeByField } from "@capsulecraft/serializer";

const pkg = "0xea0bd29742a6e8d0d50fa72ed772894f8d87c8a3d11088c8d79fc8049d54a996";
const mnemonics = "invest half dress clay green task scare hood quiz good glory angry";

// Setup connection
const connection = new Connection({ fullnode: "http://127.0.0.1:9000" });
const provider = new JsonRpcProvider(connection);

const keypair = Ed25519Keypair.deriveKeypair(mnemonics);
const signer = new RawSigner(keypair, provider);

// Type definitions

type Schema = Record<string, string>;

interface SetSerializeFieldOpts {
  objectId: string;
  type: Uint8Array;
  field: Uint8Array;
  value: Uint8Array;
}

interface RemoveFieldOpts {
  objectId: string;
  field: Uint8Array;
}

interface SetSerializeFieldsOpts {
  objectId: string;
  fields: Uint8Array[];
  types: Uint8Array[];
  values: Uint8Array[];
}

interface DeserializeFieldsOpts {
  objectId: string;
  schema: Schema;
}

// register `UID` alias
bcs.registerAlias("UID", "address");

async function createObject() {
  const txb = new TransactionBlock();

  txb.moveCall({
    arguments: [],
    typeArguments: [],
    target: `${pkg}::attach::create_object`,
  });

  const response = await signer.signAndExecuteTransactionBlock({ transactionBlock: txb });
  return { digest: response.digest };
}

async function setSerializedField(opts: SetSerializeFieldOpts) {
  const txb = new TransactionBlock();

  txb.moveCall({
    arguments: [txb.object(opts.objectId), txb.pure(opts.field), txb.pure(opts.type), txb.pure(Array.from(opts.value))],
    target: `${pkg}::attach::deser_set_field`,
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

async function setSerializedFields(opts: SetSerializeFieldsOpts) {
  if (opts.fields.length !== opts.values.length) throw new Error("Fields and Values length must be the same");

  const txb = new TransactionBlock();

  for (let i = 0; i < opts.fields.length; i++) {
    const field = opts.fields[i];
    const value = opts.values[i];
    const type = opts.types[i];

    txb.moveCall({
      arguments: [txb.object(opts.objectId), txb.pure(field), txb.pure(type), txb.pure(Array.from(value))],
      target: `${pkg}::attach::deser_set_field`,
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
    typeArguments: [],
    arguments: [uid, txb.pure(fields)],
    target: `${pkg}::attach::view_parsed`,
  });

  const response = await provider.devInspectTransactionBlock({ transactionBlock: txb, sender: pkg });

  if (response.error) {
    throw new Error(response.error);
  }

  // @ts-expect-error
  const result = response.results[0].returnValues[0][0];
  return decodeAndDeserialize(result, opts.schema);
}

function decodeAndDeserialize(value: number[], schema: Schema) {
  const values = bcs.de("vector<vector<u8>>", Uint8Array.from(value));
  return deserializeByField(bcs, values, schema);
}

async function main() {
  type Schema = Record<string, string>;

  const schema = {
    name: "String",
    about: "String",
    age: "u8",
    isOk: "bool",
  } as Schema;

  const data = {
    name: "Rahman",
    about: "Trying to be a better person",
    age: 120,
    isOk: true,
  };

  const objectId = "0x89f38790de70b6dbb195c4249a6400de002d81582f09da1b8a74bf5d4d25b274";
  const values = serializeByField(bcs, data, schema);

  const fields = Object.keys(schema).map((key) => bcs.ser("String", key).toBytes());
  const types = Object.keys(schema).map((key) => bcs.ser("String", schema[key]).toBytes());

  console.log("===== Setting fields ======");
  await setSerializedFields({ objectId, fields, values, types });

  // retrieve and deserialize fields
  console.log("\n ===== Reading fields ======");
  const deserialized1 = await deserializeFields({ objectId, schema });
  console.log(deserialized1);

  // delete field
  delete schema.name;

  console.log("\n ===== Removing field ======");
  await removeField({ objectId, field: fields[0] });

  // retrieve and deserialize fields (excluding deleted field)
  console.log("\n ===== Reading fields ======");
  const deserialized2 = await deserializeFields({ objectId, schema });
  console.log(deserialized2);
}

main().then((v: any) => v && console.log(v));
