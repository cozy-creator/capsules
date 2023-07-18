import { bcsSource as bcs } from "../../_framework/bcs";
import { FieldsWithTypes, Type, parseTypeName } from "../../_framework/util";
import { Supply } from "../../sui/balance/structs";
import { UID } from "../../sui/object/structs";
import { Queue } from "../queue/structs";
import { Encoding } from "@mysten/bcs";
import { JsonRpcProvider, ObjectId, SuiParsedData } from "@mysten/sui.js";

/* ============================== Config =============================== */

bcs.registerStructType(
  "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::fund::Config",
  {
    public_purchase: `bool`,
    public_redeems: `bool`,
    instant_purchase: `bool`,
    instant_redeem: `bool`,
  },
);

export function isConfig(type: Type): boolean {
  return (
    type ===
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::fund::Config"
  );
}

export interface ConfigFields {
  publicPurchase: boolean;
  publicRedeems: boolean;
  instantPurchase: boolean;
  instantRedeem: boolean;
}

export class Config {
  static readonly $typeName =
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::fund::Config";
  static readonly $numTypeParams = 0;

  readonly publicPurchase: boolean;
  readonly publicRedeems: boolean;
  readonly instantPurchase: boolean;
  readonly instantRedeem: boolean;

  constructor(fields: ConfigFields) {
    this.publicPurchase = fields.publicPurchase;
    this.publicRedeems = fields.publicRedeems;
    this.instantPurchase = fields.instantPurchase;
    this.instantRedeem = fields.instantRedeem;
  }

  static fromFields(fields: Record<string, any>): Config {
    return new Config({
      publicPurchase: fields.public_purchase,
      publicRedeems: fields.public_redeems,
      instantPurchase: fields.instant_purchase,
      instantRedeem: fields.instant_redeem,
    });
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): Config {
    if (!isConfig(item.type)) {
      throw new Error("not a Config type");
    }
    return new Config({
      publicPurchase: item.fields.public_purchase,
      publicRedeems: item.fields.public_redeems,
      instantPurchase: item.fields.instant_purchase,
      instantRedeem: item.fields.instant_redeem,
    });
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): Config {
    return Config.fromFields(bcs.de([Config.$typeName], data, encoding));
  }
}

/* ============================== Witness =============================== */

bcs.registerStructType(
  "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::fund::Witness",
  {
    dummy_field: `bool`,
  },
);

export function isWitness(type: Type): boolean {
  return (
    type ===
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::fund::Witness"
  );
}

export interface WitnessFields {
  dummyField: boolean;
}

export class Witness {
  static readonly $typeName =
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::fund::Witness";
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

/* ============================== Fund =============================== */

bcs.registerStructType(
  "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::fund::Fund<S, A>",
  {
    id: `0x2::object::UID`,
    total_shares: `0x2::balance::Supply<S>`,
    net_assets: `u64`,
    share_queue: `0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::queue::Queue<S>`,
    asset_queue: `0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::queue::Queue<A>`,
    config: `0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::fund::Config`,
  },
);

export function isFund(type: Type): boolean {
  return type.startsWith(
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::fund::Fund<",
  );
}

export interface FundFields {
  id: ObjectId;
  totalShares: Supply;
  netAssets: bigint;
  shareQueue: Queue;
  assetQueue: Queue;
  config: Config;
}

export class Fund {
  static readonly $typeName =
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::fund::Fund";
  static readonly $numTypeParams = 2;

  readonly $typeArgs: [Type, Type];

  readonly id: ObjectId;
  readonly totalShares: Supply;
  readonly netAssets: bigint;
  readonly shareQueue: Queue;
  readonly assetQueue: Queue;
  readonly config: Config;

  constructor(typeArgs: [Type, Type], fields: FundFields) {
    this.$typeArgs = typeArgs;

    this.id = fields.id;
    this.totalShares = fields.totalShares;
    this.netAssets = fields.netAssets;
    this.shareQueue = fields.shareQueue;
    this.assetQueue = fields.assetQueue;
    this.config = fields.config;
  }

  static fromFields(typeArgs: [Type, Type], fields: Record<string, any>): Fund {
    return new Fund(typeArgs, {
      id: UID.fromFields(fields.id).id,
      totalShares: Supply.fromFields(`${typeArgs[0]}`, fields.total_shares),
      netAssets: BigInt(fields.net_assets),
      shareQueue: Queue.fromFields(`${typeArgs[0]}`, fields.share_queue),
      assetQueue: Queue.fromFields(`${typeArgs[1]}`, fields.asset_queue),
      config: Config.fromFields(fields.config),
    });
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): Fund {
    if (!isFund(item.type)) {
      throw new Error("not a Fund type");
    }
    const { typeArgs } = parseTypeName(item.type);

    return new Fund([typeArgs[0], typeArgs[1]], {
      id: item.fields.id.id,
      totalShares: Supply.fromFieldsWithTypes(item.fields.total_shares),
      netAssets: BigInt(item.fields.net_assets),
      shareQueue: Queue.fromFieldsWithTypes(item.fields.share_queue),
      assetQueue: Queue.fromFieldsWithTypes(item.fields.asset_queue),
      config: Config.fromFieldsWithTypes(item.fields.config),
    });
  }

  static fromBcs(
    typeArgs: [Type, Type],
    data: Uint8Array | string,
    encoding?: Encoding,
  ): Fund {
    return Fund.fromFields(
      typeArgs,
      bcs.de([Fund.$typeName, ...typeArgs], data, encoding),
    );
  }

  static fromSuiParsedData(content: SuiParsedData) {
    if (content.dataType !== "moveObject") {
      throw new Error("not an object");
    }
    if (!isFund(content.type)) {
      throw new Error(`object at ${content.fields.id} is not a Fund object`);
    }
    return Fund.fromFieldsWithTypes(content);
  }

  static async fetch(provider: JsonRpcProvider, id: ObjectId): Promise<Fund> {
    const res = await provider.getObject({
      id,
      options: { showContent: true },
    });
    if (res.error) {
      throw new Error(
        `error fetching Fund object at id ${id}: ${res.error.code}`,
      );
    }
    if (
      res.data?.content?.dataType !== "moveObject" ||
      !isFund(res.data.content.type)
    ) {
      throw new Error(`object at id ${id} is not a Fund object`);
    }
    return Fund.fromFieldsWithTypes(res.data.content);
  }
}

/* ============================== MANAGE_FUND =============================== */

bcs.registerStructType(
  "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::fund::MANAGE_FUND",
  {
    dummy_field: `bool`,
  },
);

export function isMANAGE_FUND(type: Type): boolean {
  return (
    type ===
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::fund::MANAGE_FUND"
  );
}

export interface MANAGE_FUNDFields {
  dummyField: boolean;
}

export class MANAGE_FUND {
  static readonly $typeName =
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::fund::MANAGE_FUND";
  static readonly $numTypeParams = 0;

  readonly dummyField: boolean;

  constructor(dummyField: boolean) {
    this.dummyField = dummyField;
  }

  static fromFields(fields: Record<string, any>): MANAGE_FUND {
    return new MANAGE_FUND(fields.dummy_field);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): MANAGE_FUND {
    if (!isMANAGE_FUND(item.type)) {
      throw new Error("not a MANAGE_FUND type");
    }
    return new MANAGE_FUND(item.fields.dummy_field);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): MANAGE_FUND {
    return MANAGE_FUND.fromFields(
      bcs.de([MANAGE_FUND.$typeName], data, encoding),
    );
  }
}

/* ============================== PURCHASE =============================== */

bcs.registerStructType(
  "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::fund::PURCHASE",
  {
    dummy_field: `bool`,
  },
);

export function isPURCHASE(type: Type): boolean {
  return (
    type ===
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::fund::PURCHASE"
  );
}

export interface PURCHASEFields {
  dummyField: boolean;
}

export class PURCHASE {
  static readonly $typeName =
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::fund::PURCHASE";
  static readonly $numTypeParams = 0;

  readonly dummyField: boolean;

  constructor(dummyField: boolean) {
    this.dummyField = dummyField;
  }

  static fromFields(fields: Record<string, any>): PURCHASE {
    return new PURCHASE(fields.dummy_field);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): PURCHASE {
    if (!isPURCHASE(item.type)) {
      throw new Error("not a PURCHASE type");
    }
    return new PURCHASE(item.fields.dummy_field);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): PURCHASE {
    return PURCHASE.fromFields(bcs.de([PURCHASE.$typeName], data, encoding));
  }
}

/* ============================== REDEEM =============================== */

bcs.registerStructType(
  "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::fund::REDEEM",
  {
    dummy_field: `bool`,
  },
);

export function isREDEEM(type: Type): boolean {
  return (
    type ===
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::fund::REDEEM"
  );
}

export interface REDEEMFields {
  dummyField: boolean;
}

export class REDEEM {
  static readonly $typeName =
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::fund::REDEEM";
  static readonly $numTypeParams = 0;

  readonly dummyField: boolean;

  constructor(dummyField: boolean) {
    this.dummyField = dummyField;
  }

  static fromFields(fields: Record<string, any>): REDEEM {
    return new REDEEM(fields.dummy_field);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): REDEEM {
    if (!isREDEEM(item.type)) {
      throw new Error("not a REDEEM type");
    }
    return new REDEEM(item.fields.dummy_field);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): REDEEM {
    return REDEEM.fromFields(bcs.de([REDEEM.$typeName], data, encoding));
  }
}
