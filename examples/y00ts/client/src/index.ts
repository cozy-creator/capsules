import {
  JSTypes,
  bcs,
  serializeByField,
  getSigner,
  getCreatedObjects
} from '../../../../sdk/typescript/src';
import { RawSigner } from '@mysten/sui.js';
import { execSync } from 'child_process';
import path from 'path';

// const CLI_PATH = "/Users/bytedeveloper/.cargo/bin/sui";
// const PACKAGE_PATH = "/Users/bytedeveloper/Documents/Projects/0xCapsules/capsules/examples/y00ts";
const CLI_PATH = '/home/paul/.cargo/bin/sui';
const PACKAGE_PATH = '../move_package';

const ENV_PATH = path.resolve(__dirname, '../../../../', '.env');

const displayPackageID = '0xddcad84f0d79d96535f3970fc01150a15bcbc2fd';

async function main(signer: RawSigner) {
  // This is a publish transaction; requires the Sui CLI to be installed on this machine however

  let signerAddress = '0x' + (await signer.getAddress());

  // ======= Publish Package =======
  console.log('Publishing Y00t package...');

  const modulesInBase64 = JSON.parse(
    execSync(`${CLI_PATH} move build --dump-bytecode-as-base64 --path ${PACKAGE_PATH}`, {
      encoding: 'utf-8'
    })
  );

  let moveCallTxn0 = await signer.publish({
    compiledModules: modulesInBase64,
    gasBudget: 3000
  });

  let createdObjects = getCreatedObjects(moveCallTxn0);
  let y00tPackageID = createdObjects.Immutable[0];
  let y00tPublishReceipt = createdObjects.AddressOwner[0];

  // ======= Define Creator Object =======
  console.log('Making a creator object...');

  // Fetch an on-chain existing creator schema -- commented out for now
  // let creatorSchema = await provider.getObject(creatorSchemaObjectID);

  const creatorSchema = {
    name: 'String',
    url: 'Url'
  } as const;

  // Create a schema object to be used for the creator object
  // Normally you'd just use one that already exists...
  const moveCallTxn1 = await signer.executeMoveCall({
    packageObjectId: displayPackageID,
    module: 'schema',
    function: 'create',
    typeArguments: [],
    arguments: [Object.entries(creatorSchema).map(([key, value]) => [key, value])],
    gasBudget: 2000
  });

  let creatorSchemaObjectID = getCreatedObjects(moveCallTxn1).Immutable[0];

  type Creator = JSTypes<typeof creatorSchema>;

  let creatorObject: Creator = {
    name: 'Dust Labs',
    url: 'https://www.dustlabs.com/'
  };

  // Make a creator object, add display data to it using a creator-display schema
  const moveCallTxn2 = await signer.executeMoveCall({
    packageObjectId: displayPackageID,
    module: 'creator',
    function: 'define',
    typeArguments: [],
    arguments: [
      signerAddress,
      serializeByField(bcs, creatorObject, creatorSchema),
      creatorSchemaObjectID
    ],
    gasBudget: 3000
  });

  let creatorObjectID = getCreatedObjects(moveCallTxn2).Shared[0];

  // ======= Update Creator object's display data =======
  console.log('Updating creator object...');

  creatorObject.name = 'Y00t Labs';
  let fieldsChanged = ['name'];

  const _moveCallTxn3 = await signer.executeMoveCall({
    packageObjectId: displayPackageID,
    module: 'creator',
    function: 'update',
    typeArguments: [],
    arguments: [
      creatorObjectID,
      fieldsChanged,
      serializeByField(bcs, creatorObject, creatorSchema, fieldsChanged),
      creatorSchemaObjectID,
      true
    ],
    gasBudget: 3000
  });

  // ======= Claim a package object using our publish-receipt + creator object =======
  console.log('Claiming package object...');

  const moveCallTxn4 = await signer.executeMoveCall({
    packageObjectId: displayPackageID,
    module: 'creator',
    function: 'claim_package',
    typeArguments: [],
    arguments: [creatorObjectID, y00tPublishReceipt],
    gasBudget: 3000
  });

  let packageObjectID = getCreatedObjects(moveCallTxn4).AddressOwner[0];

  // Add some display data for our package object using a package-display schema

  // ======= Define an abstract type from our Publish Receipt =======
  console.log('Defining abstract type...');

  const y00tSchema = {
    name: 'String',
    description: 'Option<String>',
    image: 'Url',
    attributes: 'VecMap'
  } as const;

  type Y00t = JSTypes<typeof y00tSchema>;

  const y00tDefault: Y00t = {
    name: 'y00t',
    description: {
      some: 'y00ts is a generative art project of 15,000 NFTs. y00topia is a curated community of builders and creators. Each y00t was designed by De Labs in Los Angeles, CA.'
    },
    image:
      'https://bafkreidc5co72clgqor54gpugde6tr4otrubjfqanj4vx4ivjwxnhqgaai.ipfs.nftstorage.link/',
    attributes: {}
  };

  // This use up way too much gas; optimize

  const moveCallTxn6 = await signer.executeMoveCall({
    packageObjectId: displayPackageID,
    module: 'abstract_type',
    function: 'define',
    typeArguments: [`${y00tPackageID}::y00t::Y00tAbstract<u8>`],
    arguments: [
      y00tPublishReceipt,
      [signerAddress],
      serializeByField(bcs, y00tDefault, y00tSchema),
      [], // We leave resolvers undefined for now
      Object.entries(y00tSchema).map(([key, value]) => [key, value])
    ],
    gasBudget: 6000
  });

  let abstractTypeObjectID = getCreatedObjects(moveCallTxn6).Shared[0];

  // ====== Produce a concrete type from our AbstractType =======
  console.log('Producing concrete type from abstract...');

  // This is too expensive for gas; optimize

  const moveCallTxn7 = await signer.executeMoveCall({
    packageObjectId: displayPackageID,
    module: 'type',
    function: 'define_from_abstract',
    typeArguments: [`${y00tPackageID}::y00t::Y00tAbstract<vector<u8>>`],
    arguments: [abstractTypeObjectID, []], // We leave data undefined
    gasBudget: 7000
  });

  // Claim a Type for our Y00t using our publisher-receipt

  // Modify some fields on our Type

  // Create a Y00t, attaching display data to it

  // Modify our Y00t's display data

  // View our Y00t, using our Type + object in a view-function

  // Send our Y00t to someone else
}

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
