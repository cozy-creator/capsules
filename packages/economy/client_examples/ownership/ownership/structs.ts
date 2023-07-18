import { Option } from "../../_dependencies/source/0x1/option/structs";
import { StructTag } from "../../_dependencies/source/0x6adaf7f9c1f7ae68b96dc85f5b069f4a6aabc748d8d741184ca5479fb4466bae/struct-tag/structs";
import { bcsSource as bcs } from "../../_framework/bcs";
import { FieldsWithTypes, Type } from "../../_framework/util";
import { Encoding } from "@mysten/bcs";

/* ============================== Ownership =============================== */

bcs.registerStructType(
  "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::Ownership",
  {
    owner: `0x1::option::Option<address>`,
    transfer_auth: `0x1::option::Option<address>`,
    type: `0x6adaf7f9c1f7ae68b96dc85f5b069f4a6aabc748d8d741184ca5479fb4466bae::struct_tag::StructTag`,
  },
);

export function isOwnership(type: Type): boolean {
  return (
    type ===
    "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::Ownership"
  );
}

export interface OwnershipFields {
  owner: string | null;
  transferAuth: string | null;
  type: StructTag;
}

export class Ownership {
  static readonly $typeName =
    "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::Ownership";
  static readonly $numTypeParams = 0;

  readonly owner: string | null;
  readonly transferAuth: string | null;
  readonly type: StructTag;

  constructor(fields: OwnershipFields) {
    this.owner = fields.owner;
    this.transferAuth = fields.transferAuth;
    this.type = fields.type;
  }

  static fromFields(fields: Record<string, any>): Ownership {
    return new Ownership({
      owner: Option.fromFields<string>(`address`, fields.owner).vec[0] || null,
      transferAuth:
        Option.fromFields<string>(`address`, fields.transfer_auth).vec[0] ||
        null,
      type: StructTag.fromFields(fields.type),
    });
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): Ownership {
    if (!isOwnership(item.type)) {
      throw new Error("not a Ownership type");
    }
    return new Ownership({
      owner:
        item.fields.owner !== null
          ? Option.fromFieldsWithTypes<string>({
              type: "0x1::option::Option<" + `address` + ">",
              fields: { vec: [item.fields.owner] },
            }).vec[0]
          : null,
      transferAuth:
        item.fields.transfer_auth !== null
          ? Option.fromFieldsWithTypes<string>({
              type: "0x1::option::Option<" + `address` + ">",
              fields: { vec: [item.fields.transfer_auth] },
            }).vec[0]
          : null,
      type: StructTag.fromFieldsWithTypes(item.fields.type),
    });
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): Ownership {
    return Ownership.fromFields(bcs.de([Ownership.$typeName], data, encoding));
  }
}

/* ============================== Key =============================== */

bcs.registerStructType(
  "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::Key",
  {
    dummy_field: `bool`,
  },
);

export function isKey(type: Type): boolean {
  return (
    type ===
    "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::Key"
  );
}

export interface KeyFields {
  dummyField: boolean;
}

export class Key {
  static readonly $typeName =
    "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::Key";
  static readonly $numTypeParams = 0;

  readonly dummyField: boolean;

  constructor(dummyField: boolean) {
    this.dummyField = dummyField;
  }

  static fromFields(fields: Record<string, any>): Key {
    return new Key(fields.dummy_field);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): Key {
    if (!isKey(item.type)) {
      throw new Error("not a Key type");
    }
    return new Key(item.fields.dummy_field);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): Key {
    return Key.fromFields(bcs.de([Key.$typeName], data, encoding));
  }
}

/* ============================== FREEZE =============================== */

bcs.registerStructType(
  "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::FREEZE",
  {
    dummy_field: `bool`,
  },
);

export function isFREEZE(type: Type): boolean {
  return (
    type ===
    "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::FREEZE"
  );
}

export interface FREEZEFields {
  dummyField: boolean;
}

export class FREEZE {
  static readonly $typeName =
    "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::FREEZE";
  static readonly $numTypeParams = 0;

  readonly dummyField: boolean;

  constructor(dummyField: boolean) {
    this.dummyField = dummyField;
  }

  static fromFields(fields: Record<string, any>): FREEZE {
    return new FREEZE(fields.dummy_field);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): FREEZE {
    if (!isFREEZE(item.type)) {
      throw new Error("not a FREEZE type");
    }
    return new FREEZE(item.fields.dummy_field);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): FREEZE {
    return FREEZE.fromFields(bcs.de([FREEZE.$typeName], data, encoding));
  }
}

/* ============================== Frozen =============================== */

bcs.registerStructType(
  "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::Frozen",
  {
    dummy_field: `bool`,
  },
);

export function isFrozen(type: Type): boolean {
  return (
    type ===
    "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::Frozen"
  );
}

export interface FrozenFields {
  dummyField: boolean;
}

export class Frozen {
  static readonly $typeName =
    "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::Frozen";
  static readonly $numTypeParams = 0;

  readonly dummyField: boolean;

  constructor(dummyField: boolean) {
    this.dummyField = dummyField;
  }

  static fromFields(fields: Record<string, any>): Frozen {
    return new Frozen(fields.dummy_field);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): Frozen {
    if (!isFrozen(item.type)) {
      throw new Error("not a Frozen type");
    }
    return new Frozen(item.fields.dummy_field);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): Frozen {
    return Frozen.fromFields(bcs.de([Frozen.$typeName], data, encoding));
  }
}

/* ============================== INITIALIZE =============================== */

bcs.registerStructType(
  "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::INITIALIZE",
  {
    dummy_field: `bool`,
  },
);

export function isINITIALIZE(type: Type): boolean {
  return (
    type ===
    "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::INITIALIZE"
  );
}

export interface INITIALIZEFields {
  dummyField: boolean;
}

export class INITIALIZE {
  static readonly $typeName =
    "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::INITIALIZE";
  static readonly $numTypeParams = 0;

  readonly dummyField: boolean;

  constructor(dummyField: boolean) {
    this.dummyField = dummyField;
  }

  static fromFields(fields: Record<string, any>): INITIALIZE {
    return new INITIALIZE(fields.dummy_field);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): INITIALIZE {
    if (!isINITIALIZE(item.type)) {
      throw new Error("not a INITIALIZE type");
    }
    return new INITIALIZE(item.fields.dummy_field);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): INITIALIZE {
    return INITIALIZE.fromFields(
      bcs.de([INITIALIZE.$typeName], data, encoding),
    );
  }
}

/* ============================== IsDestroyed =============================== */

bcs.registerStructType(
  "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::IsDestroyed",
  {
    dummy_field: `bool`,
  },
);

export function isIsDestroyed(type: Type): boolean {
  return (
    type ===
    "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::IsDestroyed"
  );
}

export interface IsDestroyedFields {
  dummyField: boolean;
}

export class IsDestroyed {
  static readonly $typeName =
    "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::IsDestroyed";
  static readonly $numTypeParams = 0;

  readonly dummyField: boolean;

  constructor(dummyField: boolean) {
    this.dummyField = dummyField;
  }

  static fromFields(fields: Record<string, any>): IsDestroyed {
    return new IsDestroyed(fields.dummy_field);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): IsDestroyed {
    if (!isIsDestroyed(item.type)) {
      throw new Error("not a IsDestroyed type");
    }
    return new IsDestroyed(item.fields.dummy_field);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): IsDestroyed {
    return IsDestroyed.fromFields(
      bcs.de([IsDestroyed.$typeName], data, encoding),
    );
  }
}

/* ============================== MIGRATE =============================== */

bcs.registerStructType(
  "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::MIGRATE",
  {
    dummy_field: `bool`,
  },
);

export function isMIGRATE(type: Type): boolean {
  return (
    type ===
    "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::MIGRATE"
  );
}

export interface MIGRATEFields {
  dummyField: boolean;
}

export class MIGRATE {
  static readonly $typeName =
    "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::MIGRATE";
  static readonly $numTypeParams = 0;

  readonly dummyField: boolean;

  constructor(dummyField: boolean) {
    this.dummyField = dummyField;
  }

  static fromFields(fields: Record<string, any>): MIGRATE {
    return new MIGRATE(fields.dummy_field);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): MIGRATE {
    if (!isMIGRATE(item.type)) {
      throw new Error("not a MIGRATE type");
    }
    return new MIGRATE(item.fields.dummy_field);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): MIGRATE {
    return MIGRATE.fromFields(bcs.de([MIGRATE.$typeName], data, encoding));
  }
}

/* ============================== TRANSFER =============================== */

bcs.registerStructType(
  "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::TRANSFER",
  {
    dummy_field: `bool`,
  },
);

export function isTRANSFER(type: Type): boolean {
  return (
    type ===
    "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::TRANSFER"
  );
}

export interface TRANSFERFields {
  dummyField: boolean;
}

export class TRANSFER {
  static readonly $typeName =
    "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::TRANSFER";
  static readonly $numTypeParams = 0;

  readonly dummyField: boolean;

  constructor(dummyField: boolean) {
    this.dummyField = dummyField;
  }

  static fromFields(fields: Record<string, any>): TRANSFER {
    return new TRANSFER(fields.dummy_field);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): TRANSFER {
    if (!isTRANSFER(item.type)) {
      throw new Error("not a TRANSFER type");
    }
    return new TRANSFER(item.fields.dummy_field);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): TRANSFER {
    return TRANSFER.fromFields(bcs.de([TRANSFER.$typeName], data, encoding));
  }
}

/* ============================== UID_MUT =============================== */

bcs.registerStructType(
  "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::UID_MUT",
  {
    dummy_field: `bool`,
  },
);

export function isUID_MUT(type: Type): boolean {
  return (
    type ===
    "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::UID_MUT"
  );
}

export interface UID_MUTFields {
  dummyField: boolean;
}

export class UID_MUT {
  static readonly $typeName =
    "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::ownership::UID_MUT";
  static readonly $numTypeParams = 0;

  readonly dummyField: boolean;

  constructor(dummyField: boolean) {
    this.dummyField = dummyField;
  }

  static fromFields(fields: Record<string, any>): UID_MUT {
    return new UID_MUT(fields.dummy_field);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): UID_MUT {
    if (!isUID_MUT(item.type)) {
      throw new Error("not a UID_MUT type");
    }
    return new UID_MUT(item.fields.dummy_field);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): UID_MUT {
    return UID_MUT.fromFields(bcs.de([UID_MUT.$typeName], data, encoding));
  }
}
