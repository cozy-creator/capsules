import { assert } from 'superstruct';
import {
  deserializeBcs,
  JSTypes,
  moveStructValidator,
  serializeByField,
  parseViewResults,
  bcs
} from '../src';
import { objectID, packageID, provider, publicKey, schemaID, signer } from './config';

// Define a schema (don't forget to add `as const`)
const outlawSchema = {
  name: 'string',
  description: 'Option<string>',
  image: 'string',
  power_level: 'u64'
} as const;

// Create the schema validator
const outlawValidator = moveStructValidator(outlawSchema);

// Define the schema type
type Outlaw = JSTypes<typeof outlawSchema>;

// Create an object of type `Outlaw`
const kyrie: Outlaw = {
  name: 'Kyrie',
  description: { none: null },
  image: 'https://pbs.twimg.com/profile_images/1569727324081328128/7sUnJvRg_400x400.jpg',
  power_level: 199n
};

// Validate on runtime that your object complies with the schema
assert(kyrie, outlawValidator);

// Register the new type `Outlaw` to bcs
bcs.registerStructType('Outlaw', outlawSchema);

async function create(data: Outlaw) {
  const byteArray = serializeByField(bcs, data, outlawSchema);
  const moveCallTxn = await signer.executeMoveCall({
    packageObjectId: packageID,
    module: 'outlaw_sky',
    function: 'create',
    typeArguments: [],
    // @ts-ignore
    arguments: [schemaID, byteArray],
    gasBudget: 12000
  });
  return moveCallTxn;
}

// Read from the sui blockchain
async function read(objectID: string, dataType: string): Promise<Record<string, string>> {
  const result = await provider.devInspectTransaction(publicKey, {
    kind: 'moveCall',
    data: {
      packageObjectId: packageID,
      module: 'outlaw_sky',
      function: 'view',
      typeArguments: [],
      arguments: [objectID, schemaID]
    }
  });

  console.log(result);
  const data = parseViewResults(result);
  const outlaw = deserializeBcs(bcs, dataType, data);
  return outlaw;
}

async function readSubset() {
  const keysToRead = [];
}

async function update(objectID: string, keysToUpdate: string[], data: Outlaw) {
  const byteArray = serializeByField(bcs, data, outlawSchema, keysToUpdate);
  const moveCallTxn = await signer.executeMoveCall({
    packageObjectId: packageID,
    module: 'outlaw_sky',
    function: 'overwrite',
    typeArguments: [],
    // @ts-ignore
    arguments: [objectID, keysToUpdate, byteArray, schemaID],
    gasBudget: 12000
  });
}

async function updateAll() {}

async function deleteSubset() {}

async function deleteAll() {}

async function fullCycle() {}

create(kyrie).then(r => {
  console.log('Create function result:', r);
});

read(objectID, 'Outlaw').then(r => {
  console.log('Read function result:', r);
});

kyrie.name = 'newKyrie';
kyrie.power_level = 50n;
update(objectID, ['name', 'power_level'], kyrie).then(r => {
  console.log('Update function result:', r);
});
