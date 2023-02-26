import { MoveCallTransaction, UnserializedSignableTransaction } from '@mysten/sui.js';
import { assert } from 'superstruct';
import {
  JSTypes,
  moveStructValidator,
  serializeByField,
  parseViewResultsFromVector,
  bcs,
  getSigner,
  getAddress,
  provider
} from '../../../../sdk/typescript/src/';
import { outlawObjectID, outlawSkyPackageID, schemaObjectID } from './config';
import path from 'path';

const ENV_PATH = path.resolve(__dirname, '../../../../', '.env');

// Step 1: Define your schema
const outlawSchema = {
  name: 'String',
  description: 'Option<String>',
  image: 'String',
  power_level: 'u64',
  attributes: 'VecMap'
} as const; // Ensure the schema fields cannot be modified

// Create the schema validator
const outlawValidator = moveStructValidator(outlawSchema);

// Define the schema type
type Outlaw = JSTypes<typeof outlawSchema>;

// Create an object of type `Outlaw`
const kyrie: Outlaw = {
  name: 'Kyrie',
  description: { none: null },
  image: 'https://pbs.twimg.com/profile_images/1569727324081328128/7sUnJvRg_400x400.jpg',
  power_level: 199n,
  attributes: { Background: 'White', Face: 'Wholesome' }
};

// Validate on runtime that your object complies with the schema
assert(kyrie, outlawValidator);

// Register the new type `Outlaw` to bcs
bcs.registerStructType('Outlaw', outlawSchema);

async function create(data: Outlaw) {
  const byteArray = serializeByField(bcs, data, outlawSchema);

  const moveCallTxn = await getSigner(ENV_PATH).then(signer =>
    signer.executeMoveCall({
      packageObjectId: outlawSkyPackageID,
      module: 'outlaw_sky',
      function: 'create',
      typeArguments: [],
      /// @ts-ignore
      arguments: [schemaObjectID, byteArray],
      gasBudget: 12000
    })
  );
  return moveCallTxn;
}

// Read from the sui blockchain
async function read(outlawObjectID: string, dataType: string): Promise<Record<string, string>> {
  // const result = await provider.devInspectTransaction(publicKey, {
  //   kind: 'moveCall',
  //   data: {
  //     packageObjectId: outlawSkyPackageID,
  //     module: 'outlaw_sky',
  //     function: 'view_all',
  //     typeArguments: [],
  //     arguments: [outlawObjectID, schemaObjectID]
  //   } as MoveCallTransaction
  // } as UnserializedSignableTransaction);

  const signableTxn = {
    kind: 'moveCall',
    data: {
      packageObjectId: '0x34cf4b9fb4a5dce02a7ca003f2cc619dd0c9c54e',
      module: 'outlaw_sky',
      function: 'view_all',
      typeArguments: [],
      arguments: [
        '0x20def772eba38237b331faa2870113f05abbed42',
        '0x6bd0af67e5634dca308f4674b9e770bb2b1f0bc6'
      ]
    } as MoveCallTransaction
  } as UnserializedSignableTransaction;

  let result = await provider.devInspectTransaction(await getAddress(ENV_PATH), signableTxn);

  // This doesn't work yet, but eventually we'll want to use it instead.
  //
  // const result = await provider.devInspectTransaction(publicKey, {
  //   kind: 'moveCall',
  //   data: {
  //     packageObjectId: '0xa7b5d34fd01c30201076521b6feb2b4b5e0c7532',
  //     module: 'metadata',
  //     function: 'view_all',
  //     typeArguments: [],
  //     arguments: [
  //       '0x3fcd6d18b440acc67d2a40afc40357b29681fb51',
  //       '0x6bd0af67e5634dca308f4674b9e770bb2b1f0bc6'
  //     ]
  //   }
  // });

  console.log('response is: ', result);
  const data = parseViewResultsFromVector(result);
  const outlaw = bcs.de(dataType, data);
  return outlaw;
}

async function readSubset() {
  const keysToRead = [];
}

async function update(outlawObjectID: string, keysToUpdate: string[], data: Outlaw) {
  const byteArray = serializeByField(bcs, data, outlawSchema, keysToUpdate);
  const moveCallTxn = await getSigner(ENV_PATH).then(signer =>
    signer.executeMoveCall({
      packageObjectId: outlawSkyPackageID,
      module: 'outlaw_sky',
      function: 'overwrite',
      typeArguments: [],
      /// @ts-ignore
      arguments: [outlawObjectID, keysToUpdate, byteArray, schemaObjectID],
      gasBudget: 12000
    })
  );
}

async function updateAll() {}

async function deleteSubset() {}

async function deleteAll() {}

async function fullCycle() {}

// create(kyrie).then(r => {
//   console.log('Create function result:', r);
// });

console.log('trying...');

// read(outlawObjectID, 'Outlaw');

// read(outlawObjectID, 'Outlaw').then(r => {
//   console.log('Read function result:', r);
// });

// kyrie.name = 'newKyrie';
// kyrie.power_level = 50n;
// update(outlawObjectID, ['name', 'power_level'], kyrie).then(r => {
//   console.log('Update function result:', r);
// });
