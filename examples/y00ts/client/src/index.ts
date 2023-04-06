import {
  JSTypes,
  bcs,
  serializeByField,
  getSigner,
  getCreatedObjects,
  newSerializer
} from '../../../../sdk/typescript/src';
import {
  RawSigner,
  normalizeSuiObjectId,
  fromB64,
  TransactionBlock,
  SuiTransactionBlockResponse
} from '@mysten/sui.js';
import { execSync } from 'child_process';
import path from 'path';

// This path might vary on other machines--it requires the latest Sui CLI to be installed
const CLI_PATH = '~/.cargo/bin/sui';
const PACKAGE_PATH = '../move_package';
const ENV_PATH = path.resolve(__dirname, '../../../../', '.env');

// Devnet addresses
const attachPackageID = '0xef6aaed4bdc512470fbb85e27e4fa9c88962b409410e807ed3ad2e63bde1caba';
const displayPackageID = '0xbd0da70fa80ce1b43da7d9058dc7c6c7f8281a9a447a2ce5216815bab33bd5ee';
const ownershipPackageID = '0xf01e5f373cacb8f7c101b53de83d3b33504f127ba3e0ecb3038d55b5fba389aa';
const scriptTxPackageID = '0x1579f09714588edf97ba4ee9d4cf38978021167fd3787472239926089fbeb93e';

// These are the options for the transaction block
const options = {
  showInput: true,
  showEffects: true,
  showEvents: true,
  showObjectChanges: true
};

async function main(signer: RawSigner) {
  let signerAddress = await signer.getAddress(); // we don't add 0x here
  let tx = new TransactionBlock();

  console.log('signer: ', signerAddress);

  // ======= Transaction 1: Publish Package =======
  // ==============================================
  // ==============================================
  // This requires the Sui CLI to be installed on this machine; I think this is a hard constraint
  console.log('Publishing Y00t package...');

  const modulesInBase64 = JSON.parse(
    execSync(`${CLI_PATH} move build --dump-bytecode-as-base64 --path ${PACKAGE_PATH}`, {
      encoding: 'utf-8'
    })
  );
  tx.setGasBudget(4000); // We have to set this manually since it fails to estimate

  tx.publish(
    modulesInBase64.modules.map((m: any) => Array.from(fromB64(m))),
    modulesInBase64.dependencies.map((addr: string) => normalizeSuiObjectId(addr))
  );
  const tx1Response = await signer.signAndExecuteTransactionBlock({
    transactionBlock: tx,
    options
  });

  // TO DO: This is not currently working for some reason
  let y00tPublishReceiptID = parseTxResponse(tx1Response, 'created', 'PublishReceipt');
  console.log({ tx1Response });

  // ======= Transaction 2: Create Creator Object =======
  // ==============================================
  // ==============================================
  // Gas benchmark (devnet): 5,004 nanoSUI
  console.log('Making a creator object...');

  tx = new TransactionBlock();
  tx.moveCall({
    target: `${displayPackageID}::creator::create`,
    arguments: [tx.pure(signerAddress)]
  });
  const tx2Response = await signer.signAndExecuteTransactionBlock({
    transactionBlock: tx,
    options
  });

  let creatorObjectID = parseTxResponse(tx2Response, 'created', 'Creator');
  console.log('creatorObjectID: ', creatorObjectID);

  // ======= Transaction 3: Attach Data to Creator Object =======
  // ==============================================
  // ==============================================
  // Gas benchmark (devnet): 1,122 nanoSUI
  console.log('Attaching data to creator object...');

  // Create a schema we can serialize with, then serialize it
  const creatorSchema = {
    name: 'String',
    homepage: 'Url',
    collection_size: 'u64'
  } as const;

  type Creator = JSTypes<typeof creatorSchema>;

  let creatorData: Creator = {
    name: 'Dust Labs',
    homepage: new URL('https://www.dustlabs.com/'),
    collection_size: 15000n
  };

  let [data, fields] = newSerializer(bcs, creatorData, creatorSchema);

  // Construct an auth object
  tx = new TransactionBlock();
  let [auth] = tx.moveCall({
    target: `${ownershipPackageID}::tx_authority::begin`,
    arguments: []
  });

  // Attach data to the creator object
  tx.moveCall({
    target: `${scriptTxPackageID}::display_creator::deserialize_and_set_`,
    arguments: [tx.object(creatorObjectID), tx.pure([]), tx.pure(data), tx.pure(fields), auth]
  });

  const tx3Response = await signer.signAndExecuteTransactionBlock({
    transactionBlock: tx,
    options
  });
  console.log({ tx3Response });

  // ======= Transaction 4: Update Creator Object's Data =======
  // ==============================================
  // ==============================================
  // Gas benchmark (devnet): 5,097 (why was this more expensive??? Checking the schema?)
  console.log('Updating data on creator object...');

  const creatorSchema2 = {
    name: 'String',
    twitter: 'Url',
    icon: 'Url',
    message: 'String'
  } as const;

  type Creator2 = JSTypes<typeof creatorSchema2>;

  let creatorData2: Creator2 = {
    name: 'Y00ts Labs',
    twitter: new URL('https://twitter.com/y00tsNFT'),
    icon: new URL('https://pbs.twimg.com/profile_images/1588399574430806018/oBYKtGnj_400x400.jpg'),
    message: 'You can now migrate your y00ts to Polygon.'
  };

  tx = new TransactionBlock();
  [auth] = tx.moveCall({
    target: `${ownershipPackageID}::tx_authority::begin`,
    arguments: []
  });

  [data, fields] = newSerializer(bcs, creatorData2, creatorSchema2);

  // Attach data to the creator object
  tx.moveCall({
    target: `${scriptTxPackageID}::display_creator::deserialize_and_set_`,
    arguments: [tx.object(creatorObjectID), tx.pure([]), tx.pure(data), tx.pure(fields), auth]
  });

  // Remove two fields
  tx.moveCall({
    target: `${scriptTxPackageID}::display_creator::remove`,
    arguments: [tx.object(creatorObjectID), tx.pure([]), tx.pure(['collection_size', 'icon']), auth]
  });

  const tx4Response = await signer.signAndExecuteTransactionBlock({
    transactionBlock: tx,
    options
  });
  console.log({ tx4Response });

  // ======= Transaction 5: Claim a package object using our publish-receipt + creator object =======
  // ==============================================
  // ==============================================
  // Gas benchmark (devnet): ???
  console.log('Claiming package object...');

  tx = new TransactionBlock();
  [auth] = tx.moveCall({
    target: `${displayPackageID}::package::claim_package`,
    arguments: [tx.object(creatorObjectID), tx.object(y00tPublishReceiptID)]
  });

  const tx5Response = await signer.signAndExecuteTransactionBlock({
    transactionBlock: tx,
    options
  });
  console.log({ tx5Response });

  // Add some display data for our package object using a package-display schema
}

type objectType =
  | 'published'
  | 'transferred'
  | 'created'
  | 'mutated'
  | 'deleted'
  | 'wrapped'
  | 'created';

function parseTxResponse(res: SuiTransactionBlockResponse, type: objectType, name: string): string {
  let objectID = '';

  if (res.objectChanges) {
    console.log('changes here');
    console.log(res.objectChanges);

    switch (type) {
      case 'published':
        let publishedObject = res.objectChanges.find(obj => obj.type === type);
        // @ts-ignore
        objectID = publishedObject.packageId;
        break;
      case 'created':
        let createdObject = res.objectChanges.find(
          obj => obj.type === type && obj.objectType.includes(name)
        );
        // @ts-ignore
        objectID = createdObject.objectId;
        break;
    }
  }

  return objectID;
}

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
  name: 'String',
  description: 'Option<String>',
  image: 'String',
  attributes: 'VecMap'
} as const;

// Define the schema type in TypeScript
type NFT = JSTypes<typeof NFTSchema>;

// Create an object of type `NFT`
const y00t: NFT = {
  name: 'y00t #8173',
  description: { none: null },
  image: 'https://metadata.y00ts.com/y/8172.png',
  attributes: {
    Background: 'White',
    Fur: 'Paradise Green',
    Face: 'Wholesome',
    Clothes: 'Summer Shirt',
    Head: 'Beanie (blackout)',
    Eyewear: 'Melrose Bricks',
    '1/1': 'None'
  }
};

// Step 2: Create a Schema-validator; we can check to make sure objects comply with our schema at runtime

// Step 3: Register the new type 'NFT' with BCS so we can serialize using BCS

bcs.registerStructType('NFT', NFTSchema);
let bytes = serializeByField(bcs, y00t, NFTSchema);

// Step 4: Post our serialized data to Sui

console.dir(bytes, { maxArrayLength: null });

getSigner(ENV_PATH).then(signer => main(signer));
