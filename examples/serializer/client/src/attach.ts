import { Connection, Ed25519Keypair, JsonRpcProvider, RawSigner, TransactionBlock } from "@mysten/sui.js";
import { serializeByField, bcs, deserializeByField, parseViewResultsFromStruct } from "@capsulecraft/serializer";

const pkg = "0xc0a9437f1de96847291d3806dfb699683af2910363a2dacef28a71365aba4611";
const mnemonics = "some menemonics...";

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
  const data = { name: "Abdul", about: "Trying to be a better person" };
  const objectId = "0x085f5ff49f84b9b50ff700dc771bfe655a23c5986b983e86e41b75182acdd56d";

  const values = serializeByField(bcs, data, schema);
  const fields = Object.keys(schema).map((key) => bcs.ser("String", key).toBytes());

  await setFields({ objectId, fields, values });

  const deserialized = await deserializeFields({ objectId, schema });
  console.log(deserialized);
}

main().then(console.log);
