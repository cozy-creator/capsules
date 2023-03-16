import {
  MoveCallTransaction,
  PublishTransaction,
  SuiJsonValue,
  UnserializedSignableTransaction
} from '@mysten/sui.js';
import {
  parseViewResultsFromStruct,
  bcs,
  getAddress,
  getSigner,
  provider,
  serializeByField
} from '../../../../sdk/typescript/src/';
import path from 'path';

const ENV_PATH = path.resolve(__dirname, '../../../../', '.env');

const displayPackageID = '';
const creatorSchemaObjectID = '';

// This is a publish transaction; requires the Sui CLI to be installed on this machine however
// getSigner(ENV_PATH).then(signer => {
//   const modulesInBase64 = JSON.parse(
// C:\Users\Fidik\.cargo\bin\sui.exe
//     execSync(`${~/.cargo/bin/sui.exe} move build --dump-bytecode-as-base64 --path ${packagePath}`, {
//       encoding: 'utf-8'
//     })
//   );

//   let tx: PublishTransaction = {
//     compiledModules: modulesInBase64
//   };
//   signer.publish(tx);
// });

// Step 1: Define schema, instantiate it

getSigner(ENV_PATH).then(async signer => {
  let creatorSchema = await provider.getObject(creatorSchemaObjectID);

  let creatorObject = {
    name: 'Dust Labs',
    url: 'some-website'
  };
  const data = serializeByField(bcs, creatorObject, creatorSchema);

  let signerAddress = await signer.getAddress();

  // Make a creator object, add display data to it using a creator-display schema
  const moveCallTxn = await getSigner(ENV_PATH).then(signer =>
    signer.executeMoveCall({
      packageObjectId: displayPackageID,
      module: 'creator',
      function: 'define',
      typeArguments: [],
      // @ts-ignore because Sui doesn't think Uint8Array is a valid argument lol
      arguments: [signerAddress, data, creatorSchemaObjectID],
      gasBudget: 12000
    })
  );

  // Update our creator object's display data

  // Claim a package object using our publish-receipt + creator object

  // Add some display data for our package object using a package-display schema

  // Claim an abstract type for AbstractType

  // Produce a concrete type from our AbstractType

  // Claim a Type for our Y00t using our publisher-receipt

  // Modify some fields on our Type

  // Create a Y00t, attaching display data to it

  // Modify our Y00t's display data

  // View our Y00t, using our Type + object in a view-function

  // Send our Y00t to someone else
});

const NFTSchema = {
  name: 'String',
  description: 'Option<String>',
  image: 'String',
  attributes: 'VecMap<String,String>'
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

const nftValidator = moveStructValidator(NFTSchema);
assert(y00t, nftValidator);

// Step 3: Register the new type 'NFT' with BCS so we can serialize using BCS

bcs.registerStructType('NFT', NFTSchema);
let bytes = serializeByField(bcs, y00t, NFTSchema);

// Step 4: Post our serialized data to Sui

console.dir(bytes, { maxArrayLength: null });
