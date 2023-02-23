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
  attributes: 'VecMap<String,String>',
  url: 'String'
} as const; // Ensure the schema fields cannot be modified

bcs.registerStructType('Outlaw', metadataSchema);

async function create(): Promise<SuiExecuteTransactionResponse> {
  const moveCallTxn = await signer.executeMoveCall({
    packageObjectId: outlawSkyPackageID,
    module: 'demo_factory',
    function: 'create',
    typeArguments: [],
    arguments: [],
    gasBudget: 12000
  });

  return moveCallTxn;
}

async function get(object_id: string): Promise<DevInspectResults> {
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

  return await provider.devInspectTransaction(publicKey, signableTxn);
}
