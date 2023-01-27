import { assert } from 'superstruct';
import { moveStructValidator, serialize, JSTypes } from './configure_struct';
import { parseViewResults } from './response_parser';

// ====== Define Move Schema, JSType, and StructValidator ======

const outlawSchema = {
  name: 'ascii',
  // description: 'Option<ascii>',
  image: 'ascii',
  power_level: 'u64'
} as const;

let outlawValidator = moveStructValidator(outlawSchema);

type Outlaw = JSTypes<typeof outlawSchema>;

// ====== Instantiate and Validate ======


const kyrie: Outlaw = {
  name: 'Kyrie',
  // description: { none: null },
  image: 'https://www.wikipedia.org/',
  power_level: 199n
};

assert(kyrie, outlawValidator);

// ====== Interact with the Sui Network ======

import { bcs, signer, provider } from './configure_bcs';

const OUTLAW_SKY_PACKAGE_ID = '0x8af0cbf8380f7738907ef9aee9aab4e34c3d0716';
const SCHEMA_ID = '0x37cef7c69de4b1cea22f1ef445940432d6968ac6';

// How do we know that our JS Schema here == the Move Schema on-chain?
// We can enter an ObjectID, and assume that its contents == our JS Schema here

bcs.registerStructType('Outlaw', outlawSchema);
let kyrieBytes = serialize(bcs, 'Outlaw', kyrie);

console.log(kyrieBytes);

// This will post data as vector<u8>
async function create() {
  const moveCallTxn = await signer.executeMoveCall({
    packageObjectId: OUTLAW_SKY_PACKAGE_ID,
    module: 'outlaw_sky',
    function: 'create',
    typeArguments: [],
    arguments: [SCHEMA_ID, kyrieBytes],
    gasBudget: 15000
  });
}

async function readAll() {
  let result = await provider.devInspectMoveCall('0xed2c39b73e055240323cf806a7d8fe46ced1cabb', {
    packageObjectId: '0x8af0cbf8380f7738907ef9aee9aab4e34c3d0716',
    module: 'outlaw_sky',
    function: 'view',
    typeArguments: [],
    arguments: [
      '0xc6c3028a0df2eb49af8cf766971c9b2cf5a8d0c2',
      '0x37cef7c69de4b1cea22f1ef445940432d6968ac6'
    ]
  });
  console.log("result", result)
  let data = parseViewResults(result);
  console.log("parsedViewResults", data);
  let outlaw = bcs.de('Outlaw', new Uint8Array(data)) as Outlaw;
  console.log("Outlaw", outlaw)
}

async function readSubset() {}

async function updateAll() {}

async function updateSubset() {
  // How do we serialize just a subset of keys, rather than the entire object?
  let KeysToUpdate = ['name', 'description'];
  let kyrieBytes = serialize(bcs, 'Outlaw', kyrie);

  let objectID = '0xc6c3028a0df2eb49af8cf766971c9b2cf5a8d0c2';
  let schemaID = '0x37cef7c69de4b1cea22f1ef445940432d6968ac6';

  const moveCallTxn = await signer.executeMoveCall({
    packageObjectId: OUTLAW_SKY_PACKAGE_ID,
    module: 'outlaw_sky',
    function: 'overwrite',
    typeArguments: [],
    // outlaw id, keys, data bytes, schema
    arguments: [objectID, KeysToUpdate, kyrieBytes, SCHEMA_ID],
    gasBudget: 15000
  });
}



readAll();
// updateSubset()
// create();

