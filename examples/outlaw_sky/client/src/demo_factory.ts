import { MoveCallTransaction, UnserializedSignableTransaction } from '@mysten/sui.js';
import {
  parseViewResultsFromStruct,
  bcs,
  getAddress,
  getSigner,
  provider
} from '../../../../sdk/typescript/src/';
import { outlawSkyPackageID } from './config';
import path from 'path';

const ENV_PATH = path.resolve(__dirname, '../../../../', '.env');

// Step 1: Define your schema
const metadataSchema = {
  attributes: 'VecMap',
  url: 'String'
} as const; // Ensure the schema fields cannot be modified

bcs.registerStructType('Outlaw', metadataSchema);

async function create() {
  const moveCallTxn = await getSigner(ENV_PATH).then(signer =>
    signer.executeMoveCall({
      packageObjectId: outlawSkyPackageID,
      module: 'demo_factory',
      function: 'create',
      typeArguments: [],
      arguments: [],
      gasBudget: 3000
    })
  );

  // @ts-ignore
  console.log(moveCallTxn.effects.effects);
  // @ts-ignore
  console.log(moveCallTxn.effects.effects.created);
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

  let result = await provider.devInspectTransaction(await getAddress(ENV_PATH), signableTxn);

  const data = parseViewResultsFromStruct(result);

  console.log(data);

  const outlaw = bcs.de('Outlaw', data);

  console.log(outlaw);
}

create();

// get('0x10365765e97a7ceca26ce528db5ecc9ff1f90a31');

// https://explorer.sui.io/address/0xed2c39b73e055240323cf806a7d8fe46ced1cabb?module=devnet_nft
