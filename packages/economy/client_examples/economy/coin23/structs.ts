import { Option } from "../../_dependencies/source/0x1/option/structs";
import { bcsSource as bcs } from "../../_framework/bcs";
import { FieldsWithTypes, Type, parseTypeName } from "../../_framework/util";
import { Balance } from "../../sui/balance/structs";
import { LinkedTable } from "../../sui/linked-table/structs";
import { UID } from "../../sui/object/structs";
import { Encoding } from "@mysten/bcs";
import { JsonRpcProvider, ObjectId, SuiParsedData } from "@mysten/sui.js";

/* ============================== Witness =============================== */

bcs.registerStructType(
  "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::Witness",
  {
    dummy_field: `bool`,
  },
);

export function isWitness(type: Type): boolean {
  return (
    type ===
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::Witness"
  );
}

export interface WitnessFields {
  dummyField: boolean;
}

export class Witness {
  static readonly $typeName =
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::Witness";
  static readonly $numTypeParams = 0;

  readonly dummyField: boolean;

  constructor(dummyField: boolean) {
    this.dummyField = dummyField;
  }

  static fromFields(fields: Record<string, any>): Witness {
    return new Witness(fields.dummy_field);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): Witness {
    if (!isWitness(item.type)) {
      throw new Error("not a Witness type");
    }
    return new Witness(item.fields.dummy_field);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): Witness {
    return Witness.fromFields(bcs.de([Witness.$typeName], data, encoding));
  }
}

/* ============================== FREEZE =============================== */

bcs.registerStructType(
  "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::FREEZE",
  {
    dummy_field: `bool`,
  },
);

export function isFREEZE(type: Type): boolean {
  return (
    type ===
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::FREEZE"
  );
}

export interface FREEZEFields {
  dummyField: boolean;
}

export class FREEZE {
  static readonly $typeName =
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::FREEZE";
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

/* ============================== COIN23 =============================== */

bcs.registerStructType(
  "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::COIN23",
  {
    dummy_field: `bool`,
  },
);

export function isCOIN23(type: Type): boolean {
  return (
    type ===
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::COIN23"
  );
}

export interface COIN23Fields {
  dummyField: boolean;
}

export class COIN23 {
  static readonly $typeName =
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::COIN23";
  static readonly $numTypeParams = 0;

  readonly dummyField: boolean;

  constructor(dummyField: boolean) {
    this.dummyField = dummyField;
  }

  static fromFields(fields: Record<string, any>): COIN23 {
    return new COIN23(fields.dummy_field);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): COIN23 {
    if (!isCOIN23(item.type)) {
      throw new Error("not a COIN23 type");
    }
    return new COIN23(item.fields.dummy_field);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): COIN23 {
    return COIN23.fromFields(bcs.de([COIN23.$typeName], data, encoding));
  }
}

/* ============================== Coin23 =============================== */

bcs.registerStructType(
  "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::Coin23<T>",
  {
    id: `0x2::object::UID`,
    available: `0x2::balance::Balance<T>`,
    rebills: `0x2::linked_table::LinkedTable<address, vector<0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::Rebill>>`,
    held_funds: `0x2::linked_table::LinkedTable<address, 0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::Hold<T>>`,
    frozen: `bool`,
  },
);

export function isCoin23(type: Type): boolean {
  return type.startsWith(
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::Coin23<",
  );
}

export interface Coin23Fields {
  id: ObjectId;
  available: Balance;
  rebills: LinkedTable<string>;
  heldFunds: LinkedTable<string>;
  frozen: boolean;
}

export class Coin23 {
  static readonly $typeName =
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::Coin23";
  static readonly $numTypeParams = 1;

  readonly $typeArg: Type;

  readonly id: ObjectId;
  readonly available: Balance;
  readonly rebills: LinkedTable<string>;
  readonly heldFunds: LinkedTable<string>;
  readonly frozen: boolean;

  constructor(typeArg: Type, fields: Coin23Fields) {
    this.$typeArg = typeArg;

    this.id = fields.id;
    this.available = fields.available;
    this.rebills = fields.rebills;
    this.heldFunds = fields.heldFunds;
    this.frozen = fields.frozen;
  }

  static fromFields(typeArg: Type, fields: Record<string, any>): Coin23 {
    return new Coin23(typeArg, {
      id: UID.fromFields(fields.id).id,
      available: Balance.fromFields(`${typeArg}`, fields.available),
      rebills: LinkedTable.fromFields<string>(
        [
          `address`,
          `vector<0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::Rebill>`,
        ],
        fields.rebills,
      ),
      heldFunds: LinkedTable.fromFields<string>(
        [
          `address`,
          `0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::Hold<${typeArg}>`,
        ],
        fields.held_funds,
      ),
      frozen: fields.frozen,
    });
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): Coin23 {
    if (!isCoin23(item.type)) {
      throw new Error("not a Coin23 type");
    }
    const { typeArgs } = parseTypeName(item.type);

    return new Coin23(typeArgs[0], {
      id: item.fields.id.id,
      available: new Balance(`${typeArgs[0]}`, BigInt(item.fields.available)),
      rebills: LinkedTable.fromFieldsWithTypes<string>(item.fields.rebills),
      heldFunds: LinkedTable.fromFieldsWithTypes<string>(
        item.fields.held_funds,
      ),
      frozen: item.fields.frozen,
    });
  }

  static fromBcs(
    typeArg: Type,
    data: Uint8Array | string,
    encoding?: Encoding,
  ): Coin23 {
    return Coin23.fromFields(
      typeArg,
      bcs.de([Coin23.$typeName, typeArg], data, encoding),
    );
  }

  static fromSuiParsedData(content: SuiParsedData) {
    if (content.dataType !== "moveObject") {
      throw new Error("not an object");
    }
    if (!isCoin23(content.type)) {
      throw new Error(`object at ${content.fields.id} is not a Coin23 object`);
    }
    return Coin23.fromFieldsWithTypes(content);
  }

  static async fetch(provider: JsonRpcProvider, id: ObjectId): Promise<Coin23> {
    const res = await provider.getObject({
      id,
      options: { showContent: true },
    });
    if (res.error) {
      throw new Error(
        `error fetching Coin23 object at id ${id}: ${res.error.code}`,
      );
    }
    if (
      res.data?.content?.dataType !== "moveObject" ||
      !isCoin23(res.data.content.type)
    ) {
      throw new Error(`object at id ${id} is not a Coin23 object`);
    }
    return Coin23.fromFieldsWithTypes(res.data.content);
  }
}

/* ============================== CurrencyControls =============================== */

bcs.registerStructType(
  "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::CurrencyControls<T>",
  {
    creator_can_withdraw: `bool`,
    creator_can_freeze: `bool`,
    user_transfer_enum: `u8`,
    transfer_fee: `0x1::option::Option<0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::TransferFee>`,
    export_auths: `vector<address>`,
  },
);

export function isCurrencyControls(type: Type): boolean {
  return type.startsWith(
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::CurrencyControls<",
  );
}

export interface CurrencyControlsFields {
  creatorCanWithdraw: boolean;
  creatorCanFreeze: boolean;
  userTransferEnum: number;
  transferFee: TransferFee | null;
  exportAuths: Array<string>;
}

export class CurrencyControls {
  static readonly $typeName =
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::CurrencyControls";
  static readonly $numTypeParams = 1;

  readonly $typeArg: Type;

  readonly creatorCanWithdraw: boolean;
  readonly creatorCanFreeze: boolean;
  readonly userTransferEnum: number;
  readonly transferFee: TransferFee | null;
  readonly exportAuths: Array<string>;

  constructor(typeArg: Type, fields: CurrencyControlsFields) {
    this.$typeArg = typeArg;

    this.creatorCanWithdraw = fields.creatorCanWithdraw;
    this.creatorCanFreeze = fields.creatorCanFreeze;
    this.userTransferEnum = fields.userTransferEnum;
    this.transferFee = fields.transferFee;
    this.exportAuths = fields.exportAuths;
  }

  static fromFields(
    typeArg: Type,
    fields: Record<string, any>,
  ): CurrencyControls {
    return new CurrencyControls(typeArg, {
      creatorCanWithdraw: fields.creator_can_withdraw,
      creatorCanFreeze: fields.creator_can_freeze,
      userTransferEnum: fields.user_transfer_enum,
      transferFee:
        Option.fromFields<TransferFee>(
          `0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::TransferFee`,
          fields.transfer_fee,
        ).vec[0] || null,
      exportAuths: fields.export_auths.map((item: any) => `0x${item}`),
    });
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): CurrencyControls {
    if (!isCurrencyControls(item.type)) {
      throw new Error("not a CurrencyControls type");
    }
    const { typeArgs } = parseTypeName(item.type);

    return new CurrencyControls(typeArgs[0], {
      creatorCanWithdraw: item.fields.creator_can_withdraw,
      creatorCanFreeze: item.fields.creator_can_freeze,
      userTransferEnum: item.fields.user_transfer_enum,
      transferFee:
        item.fields.transfer_fee !== null
          ? Option.fromFieldsWithTypes<TransferFee>({
              type:
                "0x1::option::Option<" +
                `0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::TransferFee` +
                ">",
              fields: { vec: [item.fields.transfer_fee] },
            }).vec[0]
          : null,
      exportAuths: item.fields.export_auths.map((item: any) => `0x${item}`),
    });
  }

  static fromBcs(
    typeArg: Type,
    data: Uint8Array | string,
    encoding?: Encoding,
  ): CurrencyControls {
    return CurrencyControls.fromFields(
      typeArg,
      bcs.de([CurrencyControls.$typeName, typeArg], data, encoding),
    );
  }
}

/* ============================== CurrencyRegistry =============================== */

bcs.registerStructType(
  "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::CurrencyRegistry",
  {
    id: `0x2::object::UID`,
  },
);

export function isCurrencyRegistry(type: Type): boolean {
  return (
    type ===
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::CurrencyRegistry"
  );
}

export interface CurrencyRegistryFields {
  id: ObjectId;
}

export class CurrencyRegistry {
  static readonly $typeName =
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::CurrencyRegistry";
  static readonly $numTypeParams = 0;

  readonly id: ObjectId;

  constructor(id: ObjectId) {
    this.id = id;
  }

  static fromFields(fields: Record<string, any>): CurrencyRegistry {
    return new CurrencyRegistry(UID.fromFields(fields.id).id);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): CurrencyRegistry {
    if (!isCurrencyRegistry(item.type)) {
      throw new Error("not a CurrencyRegistry type");
    }
    return new CurrencyRegistry(item.fields.id.id);
  }

  static fromBcs(
    data: Uint8Array | string,
    encoding?: Encoding,
  ): CurrencyRegistry {
    return CurrencyRegistry.fromFields(
      bcs.de([CurrencyRegistry.$typeName], data, encoding),
    );
  }

  static fromSuiParsedData(content: SuiParsedData) {
    if (content.dataType !== "moveObject") {
      throw new Error("not an object");
    }
    if (!isCurrencyRegistry(content.type)) {
      throw new Error(
        `object at ${content.fields.id} is not a CurrencyRegistry object`,
      );
    }
    return CurrencyRegistry.fromFieldsWithTypes(content);
  }

  static async fetch(
    provider: JsonRpcProvider,
    id: ObjectId,
  ): Promise<CurrencyRegistry> {
    const res = await provider.getObject({
      id,
      options: { showContent: true },
    });
    if (res.error) {
      throw new Error(
        `error fetching CurrencyRegistry object at id ${id}: ${res.error.code}`,
      );
    }
    if (
      res.data?.content?.dataType !== "moveObject" ||
      !isCurrencyRegistry(res.data.content.type)
    ) {
      throw new Error(`object at id ${id} is not a CurrencyRegistry object`);
    }
    return CurrencyRegistry.fromFieldsWithTypes(res.data.content);
  }
}

/* ============================== Hold =============================== */

bcs.registerStructType(
  "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::Hold<T>",
  {
    funds: `0x2::balance::Balance<T>`,
    expiry_ms: `u64`,
  },
);

export function isHold(type: Type): boolean {
  return type.startsWith(
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::Hold<",
  );
}

export interface HoldFields {
  funds: Balance;
  expiryMs: bigint;
}

export class Hold {
  static readonly $typeName =
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::Hold";
  static readonly $numTypeParams = 1;

  readonly $typeArg: Type;

  readonly funds: Balance;
  readonly expiryMs: bigint;

  constructor(typeArg: Type, fields: HoldFields) {
    this.$typeArg = typeArg;

    this.funds = fields.funds;
    this.expiryMs = fields.expiryMs;
  }

  static fromFields(typeArg: Type, fields: Record<string, any>): Hold {
    return new Hold(typeArg, {
      funds: Balance.fromFields(`${typeArg}`, fields.funds),
      expiryMs: BigInt(fields.expiry_ms),
    });
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): Hold {
    if (!isHold(item.type)) {
      throw new Error("not a Hold type");
    }
    const { typeArgs } = parseTypeName(item.type);

    return new Hold(typeArgs[0], {
      funds: new Balance(`${typeArgs[0]}`, BigInt(item.fields.funds)),
      expiryMs: BigInt(item.fields.expiry_ms),
    });
  }

  static fromBcs(
    typeArg: Type,
    data: Uint8Array | string,
    encoding?: Encoding,
  ): Hold {
    return Hold.fromFields(
      typeArg,
      bcs.de([Hold.$typeName, typeArg], data, encoding),
    );
  }
}

/* ============================== MERCHANT =============================== */

bcs.registerStructType(
  "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::MERCHANT",
  {
    dummy_field: `bool`,
  },
);

export function isMERCHANT(type: Type): boolean {
  return (
    type ===
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::MERCHANT"
  );
}

export interface MERCHANTFields {
  dummyField: boolean;
}

export class MERCHANT {
  static readonly $typeName =
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::MERCHANT";
  static readonly $numTypeParams = 0;

  readonly dummyField: boolean;

  constructor(dummyField: boolean) {
    this.dummyField = dummyField;
  }

  static fromFields(fields: Record<string, any>): MERCHANT {
    return new MERCHANT(fields.dummy_field);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): MERCHANT {
    if (!isMERCHANT(item.type)) {
      throw new Error("not a MERCHANT type");
    }
    return new MERCHANT(item.fields.dummy_field);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): MERCHANT {
    return MERCHANT.fromFields(bcs.de([MERCHANT.$typeName], data, encoding));
  }
}

/* ============================== Rebill =============================== */

bcs.registerStructType(
  "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::Rebill",
  {
    available: `u64`,
    refresh_amount: `u64`,
    refresh_cadence: `u64`,
    latest_refresh: `u64`,
  },
);

export function isRebill(type: Type): boolean {
  return (
    type ===
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::Rebill"
  );
}

export interface RebillFields {
  available: bigint;
  refreshAmount: bigint;
  refreshCadence: bigint;
  latestRefresh: bigint;
}

export class Rebill {
  static readonly $typeName =
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::Rebill";
  static readonly $numTypeParams = 0;

  readonly available: bigint;
  readonly refreshAmount: bigint;
  readonly refreshCadence: bigint;
  readonly latestRefresh: bigint;

  constructor(fields: RebillFields) {
    this.available = fields.available;
    this.refreshAmount = fields.refreshAmount;
    this.refreshCadence = fields.refreshCadence;
    this.latestRefresh = fields.latestRefresh;
  }

  static fromFields(fields: Record<string, any>): Rebill {
    return new Rebill({
      available: BigInt(fields.available),
      refreshAmount: BigInt(fields.refresh_amount),
      refreshCadence: BigInt(fields.refresh_cadence),
      latestRefresh: BigInt(fields.latest_refresh),
    });
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): Rebill {
    if (!isRebill(item.type)) {
      throw new Error("not a Rebill type");
    }
    return new Rebill({
      available: BigInt(item.fields.available),
      refreshAmount: BigInt(item.fields.refresh_amount),
      refreshCadence: BigInt(item.fields.refresh_cadence),
      latestRefresh: BigInt(item.fields.latest_refresh),
    });
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): Rebill {
    return Rebill.fromFields(bcs.de([Rebill.$typeName], data, encoding));
  }
}

/* ============================== TransferFee =============================== */

bcs.registerStructType(
  "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::TransferFee",
  {
    bps: `u64`,
    pay_to: `address`,
  },
);

export function isTransferFee(type: Type): boolean {
  return (
    type ===
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::TransferFee"
  );
}

export interface TransferFeeFields {
  bps: bigint;
  payTo: string;
}

export class TransferFee {
  static readonly $typeName =
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::TransferFee";
  static readonly $numTypeParams = 0;

  readonly bps: bigint;
  readonly payTo: string;

  constructor(fields: TransferFeeFields) {
    this.bps = fields.bps;
    this.payTo = fields.payTo;
  }

  static fromFields(fields: Record<string, any>): TransferFee {
    return new TransferFee({
      bps: BigInt(fields.bps),
      payTo: `0x${fields.pay_to}`,
    });
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): TransferFee {
    if (!isTransferFee(item.type)) {
      throw new Error("not a TransferFee type");
    }
    return new TransferFee({
      bps: BigInt(item.fields.bps),
      payTo: `0x${item.fields.pay_to}`,
    });
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): TransferFee {
    return TransferFee.fromFields(
      bcs.de([TransferFee.$typeName], data, encoding),
    );
  }
}

/* ============================== WITHDRAW =============================== */

bcs.registerStructType(
  "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::WITHDRAW",
  {
    dummy_field: `bool`,
  },
);

export function isWITHDRAW(type: Type): boolean {
  return (
    type ===
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::WITHDRAW"
  );
}

export interface WITHDRAWFields {
  dummyField: boolean;
}

export class WITHDRAW {
  static readonly $typeName =
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::coin23::WITHDRAW";
  static readonly $numTypeParams = 0;

  readonly dummyField: boolean;

  constructor(dummyField: boolean) {
    this.dummyField = dummyField;
  }

  static fromFields(fields: Record<string, any>): WITHDRAW {
    return new WITHDRAW(fields.dummy_field);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): WITHDRAW {
    if (!isWITHDRAW(item.type)) {
      throw new Error("not a WITHDRAW type");
    }
    return new WITHDRAW(item.fields.dummy_field);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): WITHDRAW {
    return WITHDRAW.fromFields(bcs.de([WITHDRAW.$typeName], data, encoding));
  }
}
