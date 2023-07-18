import { bcsSource as bcs } from "../../_framework/bcs";
import { FieldsWithTypes, Type, parseTypeName } from "../../_framework/util";
import { ID, UID } from "../../sui/object/structs";
import { Encoding } from "@mysten/bcs";
import { JsonRpcProvider, ObjectId, SuiParsedData } from "@mysten/sui.js";

/* ============================== Claim =============================== */

bcs.registerStructType(
  "0x77e53a48851512fe5707346cf90f85ae0c46b6b527b0fa04935940b0e2f38b42::claim::Claim<T>",
  {
    id: `0x2::object::UID`,
    for_account: `0x2::object::ID`,
    amount: `u64`,
    expiry_ms: `u64`,
  },
);

export function isClaim(type: Type): boolean {
  return type.startsWith(
    "0x77e53a48851512fe5707346cf90f85ae0c46b6b527b0fa04935940b0e2f38b42::claim::Claim<",
  );
}

export interface ClaimFields {
  id: ObjectId;
  forAccount: ObjectId;
  amount: bigint;
  expiryMs: bigint;
}

export class Claim {
  static readonly $typeName =
    "0x77e53a48851512fe5707346cf90f85ae0c46b6b527b0fa04935940b0e2f38b42::claim::Claim";
  static readonly $numTypeParams = 1;

  readonly $typeArg: Type;

  readonly id: ObjectId;
  readonly forAccount: ObjectId;
  readonly amount: bigint;
  readonly expiryMs: bigint;

  constructor(typeArg: Type, fields: ClaimFields) {
    this.$typeArg = typeArg;

    this.id = fields.id;
    this.forAccount = fields.forAccount;
    this.amount = fields.amount;
    this.expiryMs = fields.expiryMs;
  }

  static fromFields(typeArg: Type, fields: Record<string, any>): Claim {
    return new Claim(typeArg, {
      id: UID.fromFields(fields.id).id,
      forAccount: ID.fromFields(fields.for_account).bytes,
      amount: BigInt(fields.amount),
      expiryMs: BigInt(fields.expiry_ms),
    });
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): Claim {
    if (!isClaim(item.type)) {
      throw new Error("not a Claim type");
    }
    const { typeArgs } = parseTypeName(item.type);

    return new Claim(typeArgs[0], {
      id: item.fields.id.id,
      forAccount: item.fields.for_account,
      amount: BigInt(item.fields.amount),
      expiryMs: BigInt(item.fields.expiry_ms),
    });
  }

  static fromBcs(
    typeArg: Type,
    data: Uint8Array | string,
    encoding?: Encoding,
  ): Claim {
    return Claim.fromFields(
      typeArg,
      bcs.de([Claim.$typeName, typeArg], data, encoding),
    );
  }

  static fromSuiParsedData(content: SuiParsedData) {
    if (content.dataType !== "moveObject") {
      throw new Error("not an object");
    }
    if (!isClaim(content.type)) {
      throw new Error(`object at ${content.fields.id} is not a Claim object`);
    }
    return Claim.fromFieldsWithTypes(content);
  }

  static async fetch(provider: JsonRpcProvider, id: ObjectId): Promise<Claim> {
    const res = await provider.getObject({
      id,
      options: { showContent: true },
    });
    if (res.error) {
      throw new Error(
        `error fetching Claim object at id ${id}: ${res.error.code}`,
      );
    }
    if (
      res.data?.content?.dataType !== "moveObject" ||
      !isClaim(res.data.content.type)
    ) {
      throw new Error(`object at id ${id} is not a Claim object`);
    }
    return Claim.fromFieldsWithTypes(res.data.content);
  }
}
