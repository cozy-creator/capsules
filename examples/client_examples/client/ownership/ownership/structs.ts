import { Option } from "../../_dependencies/source/0x1/option/structs";
import { StructTag } from "../../_dependencies/source/0x3a73bc0427056f5ed45c5689af50415c55b5a2ff31e47939859a2fbece79a173/struct-tag/structs";
import { bcsSource as bcs } from "../../_framework/bcs";
import { FieldsWithTypes, Type } from "../../_framework/util";
import { Encoding } from "@mysten/bcs";

/* ============================== Ownership =============================== */

bcs.registerStructType(
  "0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::ownership::Ownership",
  {
    owner: `0x1::option::Option<address>`,
    transfer_auth: `0x1::option::Option<address>`,
    type: `0x3a73bc0427056f5ed45c5689af50415c55b5a2ff31e47939859a2fbece79a173::struct_tag::StructTag`,
  }
);

export function isOwnership(type: Type): boolean {
  return (
    type ===
    "0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::ownership::Ownership"
  );
}

export interface OwnershipFields {
  owner: string | null;
  transferAuth: string | null;
  type: StructTag;
}

export class Ownership {
  static readonly $typeName =
    "0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::ownership::Ownership";
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
  "0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::ownership::Key",
  {
    dummy_field: `bool`,
  }
);

export function isKey(type: Type): boolean {
  return (
    type ===
    "0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::ownership::Key"
  );
}

export interface KeyFields {
  dummyField: boolean;
}

export class Key {
  static readonly $typeName =
    "0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::ownership::Key";
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
  "0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::ownership::FREEZE",
  {
    dummy_field: `bool`,
  }
);

export function isFREEZE(type: Type): boolean {
  return (
    type ===
    "0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::ownership::FREEZE"
  );
}

export interface FREEZEFields {
  dummyField: boolean;
}

export class FREEZE {
  static readonly $typeName =
    "0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::ownership::FREEZE";
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
  "0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::ownership::Frozen",
  {
    dummy_field: `bool`,
  }
);

export function isFrozen(type: Type): boolean {
  return (
    type ===
    "0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::ownership::Frozen"
  );
}

export interface FrozenFields {
  dummyField: boolean;
}

export class Frozen {
  static readonly $typeName =
    "0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::ownership::Frozen";
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
  "0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::ownership::INITIALIZE",
  {
    dummy_field: `bool`,
  }
);

export function isINITIALIZE(type: Type): boolean {
  return (
    type ===
    "0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::ownership::INITIALIZE"
  );
}

export interface INITIALIZEFields {
  dummyField: boolean;
}

export class INITIALIZE {
  static readonly $typeName =
    "0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::ownership::INITIALIZE";
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
      bcs.de([INITIALIZE.$typeName], data, encoding)
    );
  }
}

/* ============================== MIGRATE =============================== */

bcs.registerStructType(
  "0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::ownership::MIGRATE",
  {
    dummy_field: `bool`,
  }
);

export function isMIGRATE(type: Type): boolean {
  return (
    type ===
    "0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::ownership::MIGRATE"
  );
}

export interface MIGRATEFields {
  dummyField: boolean;
}

export class MIGRATE {
  static readonly $typeName =
    "0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::ownership::MIGRATE";
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
  "0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::ownership::TRANSFER",
  {
    dummy_field: `bool`,
  }
);

export function isTRANSFER(type: Type): boolean {
  return (
    type ===
    "0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::ownership::TRANSFER"
  );
}

export interface TRANSFERFields {
  dummyField: boolean;
}

export class TRANSFER {
  static readonly $typeName =
    "0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::ownership::TRANSFER";
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
  "0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::ownership::UID_MUT",
  {
    dummy_field: `bool`,
  }
);

export function isUID_MUT(type: Type): boolean {
  return (
    type ===
    "0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::ownership::UID_MUT"
  );
}

export interface UID_MUTFields {
  dummyField: boolean;
}

export class UID_MUT {
  static readonly $typeName =
    "0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::ownership::UID_MUT";
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
