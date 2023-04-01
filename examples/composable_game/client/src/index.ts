import { TransactionBlock } from '@mysten/sui.js';
import { assert } from 'superstruct';
import {
  schemaToStringArray,
  JSTypes,
  moveStructValidator,
  serializeByField,
  parseViewResultsFromVector,
  bcs,
  getSigner,
  getAddress,
  provider,
  SupportedJSTypes,
  SupportedMoveTypes
} from '../../../../sdk/typescript/src/';
import { carrierConfigObjectID, carrierPackageID, scriptTxPackageID } from './config';
import path from 'path';
import { blake2bHex } from 'blakejs';

const ENV_PATH = path.resolve(__dirname, '../../../../', '.env');

// This isn't used
type CarrierClass =
  | 'Langley'
  | 'Lexington'
  | 'Yorktown'
  | 'Essex'
  | 'Midway'
  | 'Forrestal'
  | 'Kitty Hawk'
  | 'Nimitz'
  | 'Gerald R. Ford';

// You need to define a client-side schema, so all objects have the same fields and types
const carrierSchema = {
  name: 'String',
  serial_number: 'String',
  class: 'String',
  displacement: 'u32',
  length: 'u16',
  beam: 'Option<u8>',
  draft: 'Option<u8>',
  speed: 'Option<u8>'
} as const; // Ensure the schema fields cannot be modified

// Define the schema type
type Carrier = JSTypes<typeof carrierSchema>;

// Create an object of type `Carrier`
// Note that fields do not need to be defined in the same order as the schema
const oklahoma: Carrier = {
  name: 'USS Oklahoma',
  serial_number: 'BB-37',
  class: 'Nevada',
  displacement: 27500,
  draft: { none: null },
  speed: { none: null },
  beam: { some: 72 },
  length: 583
};

// Validate on runtime that your object complies with the schema
const carrierValidator = moveStructValidator(carrierSchema);
assert(oklahoma, carrierValidator);

// For this transaction to succeed, the signer's public key must be listed on the battleshipConfigObject
// as an authorized signer
async function create(
  object: Record<string, SupportedJSTypes>,
  schema: Record<string, SupportedMoveTypes>,
  owner: string
) {
  const byteArray = serializeByField(bcs, object, schema);
  const schemaFields = schemaToStringArray(schema);

  const tx = new TransactionBlock();
  tx.moveCall({
    target: `0x${carrierPackageID}::aircraft_carrier::create`,
    arguments: [
      tx.pure(byteArray),
      tx.pure(schemaFields),
      tx.pure(owner),
      tx.object(carrierConfigObjectID)
    ]
  });

  const moveCallTxn = await getSigner(ENV_PATH).then(signer =>
    signer.signAndExecuteTransactionBlock({ transactionBlock: tx })
  );
  return moveCallTxn;
}

async function read(carrierObjectID: string) {
  const tx = new TransactionBlock();

  tx.moveCall({
    target: `0x${scriptTxPackageID}::script_tx::view_all`,
    arguments: [
      tx.object(carrierObjectID),
      tx.pure(getNamespace(carrierPackageID, 'aircraft_carrier'))
    ]
  });

  const moveCallTxn = await getSigner(ENV_PATH).then(signer =>
    signer.devInspectTransactionBlock({ transactionBlock: tx })
  );

  return moveCallTxn;
}

// TO DO: check to make sure this is the same as the address generated on-chain
function getNamespace(packageID: string, moduleName: string): string {
  return blake2bHex(`${packageID}::${moduleName}::Witness`, undefined, 32);
}

// // Register the new type `Carrier` to bcs
// bcs.registerStructType('Carrier', carrierSchema);

// Let's try reading with a 'get dynamic field' call rather than a devInspect

// Let's also try devInspect
