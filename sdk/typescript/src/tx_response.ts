import { SuiTransactionBlockResponse } from '@mysten/sui.js';

export interface CreatedObject {
  owner:
    | { ObjectOwner: string }
    | { AddressOwner: string }
    | { Shared: { initial_shared_version: number } }
    | 'Immutable';
  reference: {
    objectId: string;
    version: number;
    digest: string;
  };
}

export interface ParsedResponse {
  AddressOwner: string[];
  ObjectOwner: string[];
  Immutable: string[];
  Shared: string[];
}

// TO DO: update this for v0.29 so I can get rid of the ts-ignores
export function getCreatedObjects(txResponse: SuiTransactionBlockResponse): ParsedResponse {
  let result: ParsedResponse = {
    AddressOwner: [],
    ObjectOwner: [],
    Immutable: [],
    Shared: []
  };

  if (
    'effects' in txResponse &&
    // @ts-ignore
    'effects' in txResponse.effects &&
    // @ts-ignore
    txResponse.effects.effects.created
  ) {
    // @ts-ignore
    txResponse.effects.effects.created.forEach((object: CreatedObject) => {
      switch (object.owner) {
        case 'Immutable':
          result.Immutable.push(object.reference.objectId);
          break;
        default:
          if (typeof object.owner === 'object' && 'Shared' in object.owner) {
            result.Shared.push(object.reference.objectId);
          } else if (typeof object.owner === 'object' && 'ObjectOwner' in object.owner) {
            result.ObjectOwner.push(object.reference.objectId);
          } else if (typeof object.owner === 'object' && 'AddressOwner' in object.owner) {
            result.AddressOwner.push(object.reference.objectId);
          }
      }
    });
  }

  return result;
}
