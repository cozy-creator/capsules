import { bcsSource as bcs } from "../../../../_framework/bcs";
import { FieldsWithTypes, Type } from "../../../../_framework/util";
import { Encoding } from "@mysten/bcs";

/* ============================== OrgTransfer =============================== */

bcs.registerStructType(
  "0xa34b35ca7829b27fdcc50f2823bf31778890d21e06f76207e672bf51929ad88e::org_transfer::OrgTransfer",
  {
    dummy_field: `bool`,
  },
);

export function isOrgTransfer(type: Type): boolean {
  return (
    type ===
    "0xa34b35ca7829b27fdcc50f2823bf31778890d21e06f76207e672bf51929ad88e::org_transfer::OrgTransfer"
  );
}

export interface OrgTransferFields {
  dummyField: boolean;
}

export class OrgTransfer {
  static readonly $typeName =
    "0xa34b35ca7829b27fdcc50f2823bf31778890d21e06f76207e672bf51929ad88e::org_transfer::OrgTransfer";
  static readonly $numTypeParams = 0;

  readonly dummyField: boolean;

  constructor(dummyField: boolean) {
    this.dummyField = dummyField;
  }

  static fromFields(fields: Record<string, any>): OrgTransfer {
    return new OrgTransfer(fields.dummy_field);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): OrgTransfer {
    if (!isOrgTransfer(item.type)) {
      throw new Error("not a OrgTransfer type");
    }
    return new OrgTransfer(item.fields.dummy_field);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): OrgTransfer {
    return OrgTransfer.fromFields(
      bcs.de([OrgTransfer.$typeName], data, encoding),
    );
  }
}
