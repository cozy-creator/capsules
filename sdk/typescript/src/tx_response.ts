import { SuiExecuteTransactionResponse } from '@mysten/sui.js';

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

export function getCreatedObjects(txResponse: SuiExecuteTransactionResponse): ParsedResponse {
  let result: ParsedResponse = {
    AddressOwner: [],
    ObjectOwner: [],
    Immutable: [],
    Shared: []
  };

  if (
    'effects' in txResponse &&
    'effects' in txResponse.effects &&
    txResponse.effects.effects.created
  ) {
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
