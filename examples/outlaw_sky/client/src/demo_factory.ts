import {
  DevInspectResults,
  MoveCall,
  MoveCallTransaction,
  SuiExecuteTransactionResponse,
  UnserializedSignableTransaction
} from '@mysten/sui.js';
import { assert } from 'superstruct';
import {
  JSTypes,
  moveStructValidator,
  serializeByField,
  deserializeByField,
  parseViewResultsFromStruct,
  bcs
} from '../../../../sdk/typescript/src';
import {
  outlawObjectID,
  outlawSkyPackageID,
  provider,
  publicKey,
  schemaObjectID,
  signer
} from './config';

// Step 1: Define your schema
const metadataSchema = {
  attributes: 'VecMap',
  url: 'String'
} as const; // Ensure the schema fields cannot be modified

bcs.registerStructType('Outlaw', metadataSchema);

async function create() {
  const moveCallTxn = await signer.executeMoveCall({
    packageObjectId: outlawSkyPackageID,
    module: 'demo_factory',
    function: 'create',
    typeArguments: [],
    arguments: [],
    gasBudget: 2000
  });

  // @ts-ignore
  console.log(moveCallTxn.effects.effects);
}

async function get(object_id: string) {
  const signableTxn = {
    kind: 'moveCall',
    data: {
      packageObjectId: outlawSkyPackageID,
      module: 'demo_factory',
      function: 'view',
      typeArguments: [],
      arguments: [object_id]
    } as MoveCallTransaction
  } as UnserializedSignableTransaction;

  let result = await provider.devInspectTransaction(publicKey, signableTxn);

  const data = parseViewResultsFromStruct(result);

  console.log(data);

  const outlaw = bcs.de('Outlaw', data);

  console.log(outlaw);
}

create();

// get('0x36a07d85c73261174f0d4ff0d419f77ee7e8a13d');

// https://explorer.sui.io/address/0xed2c39b73e055240323cf806a7d8fe46ced1cabb?module=devnet_nft
