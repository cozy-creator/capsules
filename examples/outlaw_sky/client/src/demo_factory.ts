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
  parseViewResults,
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
    gasBudget: 12000
  });

  console.log(moveCallTxn);
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

  const data = parseViewResults(result);
  const outlaw = bcs.de('Outlaw', data);

  console.log(outlaw);
}

get('0x7d0b60f910be9ab60ef5833b6cd8998cb7617f05');

// https://explorer.sui.io/address/0xed2c39b73e055240323cf806a7d8fe46ced1cabb?module=devnet_nft
