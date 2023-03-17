import {
  TypeTag,
  MoveCallTransaction,
  PublishTransaction,
  SuiJsonValue,
  UnserializedSignableTransaction
} from '@mysten/sui.js';
import {
  moveStructValidator,
  JSTypes,
  parseViewResultsFromStruct,
  bcs,
  getAddress,
  getSigner,
  provider,
  serializeByField
} from '../../../../sdk/typescript/src/';
import path from 'path';
import { execSync } from 'child_process';

const ENV_PATH = path.resolve(__dirname, '../../../../', '.env');
const CLI_PATH = 'C:\\Users\\Fidik\\.cargo\\bin\\sui.exe';
const PACKAGE_PATH = 'C:\\Git\\capsules\\examples\\y00ts\\move_package';

const displayPackageID = '0xc3238c1d8bbadb0f367924249ea7a74455ce5b91';

// This is a publish transaction; requires the Sui CLI to be installed on this machine however
getSigner(ENV_PATH).then(async signer => {
  // ======= Publish Package =======
  console.log('Publishing Y00t package...');

  const modulesInBase64 = JSON.parse(
    execSync(`${CLI_PATH} move build --dump-bytecode-as-base64 --path ${PACKAGE_PATH}`, {
      encoding: 'utf-8'
    })
  );

  let response = await signer.publish({
    compiledModules: modulesInBase64,
    gasBudget: 3000
  });

  // @ts-ignore because typescript doesn't think response.effects exists -- why?
  let y00tPackageID = response.effects.effects.created[0].reference.objectId as string;
  // @ts-ignore
  let y00tPublishReceipt = response.effects.effects.created[1].reference.objectId as string;

  // ======= Define Creator Object =======

  // Fetch an on-chain existing creator schema
  // let creatorSchema = await provider.getObject(creatorSchemaObjectID);

  const creatorSchema = {
    name: 'String',
    url: 'Url'
  } as const;
  // const creatorValidator = moveStructValidator(creatorSchema);

  const moveCallTxn1 = await signer.executeMoveCall({
    packageObjectId: displayPackageID,
    module: 'schema',
    function: 'create',
    typeArguments: [],
    arguments: [Object.entries(creatorSchema).map(([key, value]) => [key, value])],
    gasBudget: 2000
  });

  // @ts-ignore
  let creatorSchemaObjectID = moveCallTxn1.effects.effects.created[0].reference.objectId as string;
  console.log(creatorSchemaObjectID);

  type Creator = JSTypes<typeof creatorSchema>;

  let creatorObject: Creator = {
    name: 'Dust Labs',
    url: 'https://www.dustlabs.com/'
  };

  let signerAddress = '0x' + (await signer.getAddress());

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

  console.log('making creator object');
  // @ts-ignore
  console.log(moveCallTxn2.effects.effects);

  // @ts-ignore
  // let creatorObjectID = moveCallTxn2.effects.effects.created[0].reference.objectId as string;

  // console.log(creatorObjectID);

  // ======= Update Creator object's display data =======

  creatorObject.name = 'Y00t Labs';

  // This fails; function needs to be debugged on-chain

  // const moveCallTxn3 = await signer.executeMoveCall({
  //   packageObjectId: displayPackageID,
  //   module: 'creator',
  //   function: 'update',
  //   typeArguments: [],
  //   arguments: [
  //     creatorObjectID,
  //     ['name'],
  //     serializeByField(bcs, creatorObject, creatorSchema, ['name']),
  //     creatorSchemaObjectID,
  //     true
  //   ],
  //   gasBudget: 3000
  // });

  console.log('updating creator object');

  // ======= Claim a package object using our publish-receipt + creator object =======

  // This fails

  // const moveCallTxn4 = await signer.executeMoveCall({
  //   packageObjectId: displayPackageID,
  //   module: 'creator',
  //   function: 'claim_package',
  //   typeArguments: [],
  //   arguments: [creatorObjectID, y00tPublishReceipt],
  //   gasBudget: 3000
  // });

  console.log('claiming package object');

  // @ts-ignore
  // let packageObjectID = moveCallTxn4.effects.effects.created[0].reference.objectId as string;

  // console.log(packageObjectID);

  // Add some display data for our package object using a package-display schema

  // ======= Define an abstract type from our Publish Receipt =======

  const y00tSchema = {
    name: 'String',
    description: 'Option<String>',
    image: 'Url',
    attributes: 'VecMap'
  } as const;

  type Y00t = JSTypes<typeof y00tSchema>;

  const y00tDefault: Y00t = {
    name: 'y00t',
    description: { some: 'These guys are great' },
    image: 'https://metadata.y00ts.com/y/8172.png',
    attributes: {}
  };

  const moveCallTxn6 = await signer.executeMoveCall({
    packageObjectId: displayPackageID,
    module: 'abstract_type',
    function: 'define',
    typeArguments: [`${y00tPackageID}::y00t::Y00tAbstract<u8>`],
    arguments: [
      y00tPublishReceipt,
      signerAddress,
      serializeByField(bcs, y00tDefault, y00tSchema),
      Object.entries(y00tSchema).map(([key, value]) => [key, value])
    ],
    gasBudget: 3000
  });

  console.log('defining abstract type');

  console.log(moveCallTxn6);

  // Produce a concrete type from our AbstractType

  // Claim a Type for our Y00t using our publisher-receipt

  // Modify some fields on our Type

  // Create a Y00t, attaching display data to it

  // Modify our Y00t's display data

  // View our Y00t, using our Type + object in a view-function

  // Send our Y00t to someone else
});

getSigner(ENV_PATH).then(async signer => {});

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
