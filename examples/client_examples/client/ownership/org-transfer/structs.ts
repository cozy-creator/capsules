import { bcsSource as bcs } from "../../_framework/bcs";
import { FieldsWithTypes, Type } from "../../_framework/util";
import { Encoding } from "@mysten/bcs";

/* ============================== OrgTransfer =============================== */

bcs.registerStructType(
  "0xf167c2f8449be4da16dcf9633206228068d672f2dd2d8d8d06c5cac90dc3d1ac::org_transfer::OrgTransfer",
  {
    dummy_field: `bool`,
  }
);

export function isOrgTransfer(type: Type): boolean {
  return (
    type ===
    "0xf167c2f8449be4da16dcf9633206228068d672f2dd2d8d8d06c5cac90dc3d1ac::org_transfer::OrgTransfer"
  );
}

export interface OrgTransferFields {
  dummyField: boolean;
}

export class OrgTransfer {
  static readonly $typeName =
    "0xf167c2f8449be4da16dcf9633206228068d672f2dd2d8d8d06c5cac90dc3d1ac::org_transfer::OrgTransfer";
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
      bcs.de([OrgTransfer.$typeName], data, encoding)
    );
  }
}
