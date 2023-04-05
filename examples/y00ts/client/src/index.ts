import {
  JSTypes,
  bcs,
  serializeByField,
  getSigner,
  getCreatedObjects,
  newSerializer,
} from "../../../../sdk/typescript/src";
import {
  RawSigner,
  normalizeSuiObjectId,
  fromB64,
  TransactionBlock,
  SuiTransactionBlockResponse,
} from "@mysten/sui.js";
import { execSync } from "child_process";
import path from "path";

// TO DO: I don't know how to generalize this path yet. Right now it's hardcoded
// const CLI_PATH = "/home/paul/.cargo/bin/sui";
const CLI_PATH = "/home/george/.cargo/bin/sui";
const PACKAGE_PATH = "../move_package";
const ENV_PATH = path.resolve(__dirname, "../../../../", ".env");

// Devnet addresses
const attachPackageID = "";
const displayPackageID =
  "0xbd0da70fa80ce1b43da7d9058dc7c6c7f8281a9a447a2ce5216815bab33bd5ee";
const ownershipPackageID =
  "0xf01e5f373cacb8f7c101b53de83d3b33504f127ba3e0ecb3038d55b5fba389aa";
const scriptTxPackageID = "";

async function main(signer: RawSigner) {
  let signerAddress = await signer.getAddress(); // we don't add 0x here
  let tx = new TransactionBlock();

  console.log("signer: ", signerAddress);

  // ======= Transaction 1: Publish Package =======
  // ==============================================
  // ==============================================
  // This requires the Sui CLI to be installed on this machine; I think this is a hard constraint
  console.log("Publishing Y00t package...");

  // const modulesInBase64 = JSON.parse(
  //   execSync(`${CLI_PATH} move build --dump-bytecode-as-base64 --path ${PACKAGE_PATH}`, {
  //     encoding: 'utf-8'
  //   })
  // );

  // tx.publish(
  //   modulesInBase64.modules.map((m: any) => Array.from(fromB64(m))),
  //   modulesInBase64.dependencies.map((addr: string) => normalizeSuiObjectId(addr))
  // );
  // const result1 = await signer.signAndExecuteTransactionBlock({ transactionBlock: tx });
  // console.log({ result1 });

  // ======= Transaction 2: Create Creator Object =======
  // ==============================================
  // ==============================================
  // Gas benchmark (devnet): 5,004 nanoSUI
  console.log("Making a creator object...");

  tx = new TransactionBlock();
  tx.moveCall({
    target: `${displayPackageID}::creator::create`,
    arguments: [tx.pure(signerAddress)],
  });
  const tx2Response = await signer.signAndExecuteTransactionBlock({
    transactionBlock: tx,
    options: {
      showInput: true,
      showEffects: true,
      showEvents: true,
      showObjectChanges: true,
    },
  });
  let creatorObjectID = "";
  if (tx2Response.objectChanges) {
    const createdCreator = tx2Response.objectChanges.find(
      (obj) => obj.type === "created" && obj.objectType.includes("Creator")
    );
    console.log(createdCreator);
    // @ts-ignore
    creatorObjectID = createdCreator.objectId; // TO DO: get this from result2
    console.log("creatorObjectID: ", creatorObjectID);
  }

  // ======= Transaction 3: Attach Data to Creator Object =======
  // ==============================================
  // ==============================================

  // Create a schema we can serialize with, then serialize it
  const creatorSchema = {
    name: "String",
    url: "String",
  } as const;

  type Creator = JSTypes<typeof creatorSchema>;

  let creatorData: Creator = {
    name: "Dust Labs",
    url: "https://www.dustlabs.com/",
  };

  let [data, fields] = newSerializer(bcs, creatorData, creatorSchema);

  // Construct an auth object; this might work
  tx = new TransactionBlock();
  let [auth] = tx.moveCall({
    target: `${ownershipPackageID}::tx_authority::begin`,
    arguments: [],
  });
  const result3_0 = await signer.signAndExecuteTransactionBlock({
    transactionBlock: tx,
    options: {
      showEffects: true,
      showEvents: true,
      showObjectChanges: true,
    },
  });
  console.log("TX3 p1/2 : ", result3_0);
  // Just trying to run seperatly the transaction to identify whats wrong

  tx.moveCall({
    target: `${scriptTxPackageID}::display_creator::deserialize_and_set_`,
    arguments: [
      tx.object(creatorObjectID),
      tx.pure(null),
      tx.pure(data),
      tx.pure(fields),
      auth,
    ],
  });

  const result3 = await signer.signAndExecuteTransactionBlock({
    transactionBlock: tx,
  });
  console.log({ result3 });
}

// Fetch an on-chain existing creator schema -- commented out for now
// let creatorSchema = await provider.getObject(creatorSchemaObjectID);

// let createdObjects = getCreatedObjects(moveCallTxn0);
// let y00tPackageID = createdObjects.Immutable[0];
// let y00tPublishReceipt = createdObjects.AddressOwner[0];

// let creatorObjectID = getCreatedObjects(moveCallTxn2).Shared[0];

// // ======= Transaction 4: Update Creator Object's Data =======

// console.log('Updating creator object...');

// creatorObject.name = 'Y00t Labs';
// let fieldsChanged = ['name'];

// const _moveCallTxn3 = await signer.executeMoveCall({
//   packageObjectId: displayPackageID,
//   module: 'creator',
//   function: 'update',
//   typeArguments: [],
//   arguments: [
//     creatorObjectID,
//     fieldsChanged,
//     serializeByField(bcs, creatorObject, creatorSchema, fieldsChanged),
//     creatorSchemaObjectID,
//     true
//   ],
//   gasBudget: 3000
// });

// // ======= Transaction 5: Claim a package object using our publish-receipt + creator object =======
// console.log('Claiming package object...');

// const moveCallTxn4 = await signer.executeMoveCall({
//   packageObjectId: displayPackageID,
//   module: 'creator',
//   function: 'claim_package',
//   typeArguments: [],
//   arguments: [creatorObjectID, y00tPublishReceipt],
//   gasBudget: 3000
// });

// let packageObjectID = getCreatedObjects(moveCallTxn4).AddressOwner[0];

// // Add some display data for our package object using a package-display schema

// // ======= Transaction 6: Define an abstract type for Points<T> Publish Receipt =======
// console.log('Defining abstract type...');

// const y00tSchema = {
//   name: 'String',
//   description: 'Option<String>',
//   image: 'Url',
//   attributes: 'VecMap'
// } as const;

// type Y00t = JSTypes<typeof y00tSchema>;

// const y00tDefault: Y00t = {
//   name: 'y00t',
//   description: {
//     some: 'y00ts is a generative art project of 15,000 NFTs. y00topia is a curated community of builders and creators. Each y00t was designed by De Labs in Los Angeles, CA.'
//   },
//   image:
//     'https://bafkreidc5co72clgqor54gpugde6tr4otrubjfqanj4vx4ivjwxnhqgaai.ipfs.nftstorage.link/',
//   attributes: {}
// };

// // This use up way too much gas; optimize

// const moveCallTxn6 = await signer.executeMoveCall({
//   packageObjectId: displayPackageID,
//   module: 'abstract_type',
//   function: 'define',
//   typeArguments: [`${y00tPackageID}::y00t::Y00tAbstract<u8>`],
//   arguments: [
//     y00tPublishReceipt,
//     [signerAddress],
//     serializeByField(bcs, y00tDefault, y00tSchema),
//     [], // We leave resolvers undefined for now
//     Object.entries(y00tSchema).map(([key, value]) => [key, value])
//   ],
//   gasBudget: 6000
// });

// let abstractTypeObjectID = getCreatedObjects(moveCallTxn6).Shared[0];

// // ======= Transaction 7: Attach Data to Abstract Type =======

// // ====== Transaction 8: Produce a concrete type from our AbstractType =======
// console.log('Producing concrete type from abstract...');

// // This is too expensive for gas; optimize

// const moveCallTxn7 = await signer.executeMoveCall({
//   packageObjectId: displayPackageID,
//   module: 'type',
//   function: 'define_from_abstract',
//   typeArguments: [`${y00tPackageID}::y00t::Y00tAbstract<vector<u8>>`],
//   arguments: [abstractTypeObjectID, []], // We leave data undefined
//   gasBudget: 7000
// });

// let concreteFromAbstractTypeID = getCreatedObjects(moveCallTxn7).AddressOwner[0];

// // Claim a Type for our Y00t using our publisher-receipt
// console.log('Claiming a Type for Y00t...');

// const moveCallTxn8 = await signer.executeMoveCall({
//   packageObjectId: displayPackageID,
//   module: 'type',
//   function: 'define',
//   typeArguments: [`${y00tPackageID}::y00t::Y00t`],
//   arguments: [
//     y00tPublishReceipt,
//     serializeByField(bcs, y00tDefault, y00tSchema),
//     [], // We leave resolvers undefined for now
//     Object.entries(y00tSchema).map(([key, value]) => [key, value])
//   ],
//   gasBudget: 7000
// });

// let typeObjectID = getCreatedObjects(moveCallTxn8).AddressOwner[0];

// // ====== Transaction 9: Attach Data to Concrete Type =======

// // ====== Transaction 10: Modify Data on Concrete Type =======

// // Modify some fields on our Type
// console.log('Modifying fields on our Y00t Type...');

// // Let's create a new schema, and change to that
// const y00tSchema2 = {
//   name: 'String',
//   symbol: 'String',
//   description: 'Option<String>',
//   image: 'Url',
//   attributes: 'VecMap'
// } as const;

// type Y00t2 = JSTypes<typeof y00tSchema2>;

// const y00tDefault2: Y00t2 = {
//   name: 'unknown y00t',
//   symbol: 'Y00T'
// };

//     public entry fun set_fields<T>(
//       self: &mut Type<T>,
//       data: vector<vector<u8>>,
//       raw_fields: vector<vector<String>>,
//   ) {

// const moveCallTxn9 = await signer.executeMoveCall({
//   packageObjectId: displayPackageID,
//   module: 'type',
//   function: 'set_fields',
//   typeArguments: [`${y00tPackageID}::y00t::Y00t`],
//   arguments: [
//     typeObjectID,
//     serializeByField(bcs, y00tDefault, y00tSchema),
//     [], // We leave resolvers undefined for now
//     Object.entries(y00tSchema).map(([key, value]) => [key, value])
//   ],
//   gasBudget: 2000
// });

// // ====== Transaction 11: Create a Y00t, attach data to it =======

// // ====== Transaction 12: Modify Y00t data =======

// // ====== Transaction 13: View Y00t =======

// // ====== Transaction 14: Transfer Ownership of Y00t =======

const NFTSchema = {
  name: "String",
  description: "Option<String>",
  image: "String",
  attributes: "VecMap",
} as const;

// Define the schema type in TypeScript
type NFT = JSTypes<typeof NFTSchema>;

// Create an object of type `NFT`
const y00t: NFT = {
  name: "y00t #8173",
  description: { none: null },
  image: "https://metadata.y00ts.com/y/8172.png",
  attributes: {
    Background: "White",
    Fur: "Paradise Green",
    Face: "Wholesome",
    Clothes: "Summer Shirt",
    Head: "Beanie (blackout)",
    Eyewear: "Melrose Bricks",
    "1/1": "None",
  },
};

// Step 2: Create a Schema-validator; we can check to make sure objects comply with our schema at runtime

// Step 3: Register the new type 'NFT' with BCS so we can serialize using BCS

bcs.registerStructType("NFT", NFTSchema);
let bytes = serializeByField(bcs, y00t, NFTSchema);

// Step 4: Post our serialized data to Sui

console.dir(bytes, { maxArrayLength: null });

getSigner(ENV_PATH).then((signer) => main(signer));
