import { Option } from "../../_dependencies/source/0x1/option/structs";
import { StructTag } from "../../_dependencies/source/0x6adaf7f9c1f7ae68b96dc85f5b069f4a6aabc748d8d741184ca5479fb4466bae/struct-tag/structs";
import { bcsSource as bcs } from "../../_framework/bcs";
import { FieldsWithTypes, Type, parseTypeName } from "../../_framework/util";
import { UID } from "../../sui/object/structs";
import { Claim } from "../claim/structs";
import { Encoding } from "@mysten/bcs";
import { JsonRpcProvider, ObjectId, SuiParsedData } from "@mysten/sui.js";

/* ============================== Witness =============================== */

bcs.registerStructType(
  "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::item_offer::Witness",
  {
    dummy_field: `bool`,
  },
);

export function isWitness(type: Type): boolean {
  return (
    type ===
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::item_offer::Witness"
  );
}

export interface WitnessFields {
  dummyField: boolean;
}

export class Witness {
  static readonly $typeName =
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::item_offer::Witness";
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

/* ============================== ItemOffer =============================== */

bcs.registerStructType(
  "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::item_offer::ItemOffer<T>",
  {
    id: `0x2::object::UID`,
    send_to: `address`,
    claim: `0x1::option::Option<0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::claim::Claim<T>>`,
    for_id: `0x1::option::Option<0x2::object::ID>`,
    for_type: `0x1::option::Option<0x6adaf7f9c1f7ae68b96dc85f5b069f4a6aabc748d8d741184ca5479fb4466bae::struct_tag::StructTag>`,
    amount_each: `u64`,
    quantity: `u8`,
    expiry_ms: `u64`,
  },
);

export function isItemOffer(type: Type): boolean {
  return type.startsWith(
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::item_offer::ItemOffer<",
  );
}

export interface ItemOfferFields {
  id: ObjectId;
  sendTo: string;
  claim: Claim | null;
  forId: ObjectId | null;
  forType: StructTag | null;
  amountEach: bigint;
  quantity: number;
  expiryMs: bigint;
}

export class ItemOffer {
  static readonly $typeName =
    "0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::item_offer::ItemOffer";
  static readonly $numTypeParams = 1;

  readonly $typeArg: Type;

  readonly id: ObjectId;
  readonly sendTo: string;
  readonly claim: Claim | null;
  readonly forId: ObjectId | null;
  readonly forType: StructTag | null;
  readonly amountEach: bigint;
  readonly quantity: number;
  readonly expiryMs: bigint;

  constructor(typeArg: Type, fields: ItemOfferFields) {
    this.$typeArg = typeArg;

    this.id = fields.id;
    this.sendTo = fields.sendTo;
    this.claim = fields.claim;
    this.forId = fields.forId;
    this.forType = fields.forType;
    this.amountEach = fields.amountEach;
    this.quantity = fields.quantity;
    this.expiryMs = fields.expiryMs;
  }

  static fromFields(typeArg: Type, fields: Record<string, any>): ItemOffer {
    return new ItemOffer(typeArg, {
      id: UID.fromFields(fields.id).id,
      sendTo: `0x${fields.send_to}`,
      claim:
        Option.fromFields<Claim>(
          `0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::claim::Claim<${typeArg}>`,
          fields.claim,
        ).vec[0] || null,
      forId:
        Option.fromFields<ObjectId>(`0x2::object::ID`, fields.for_id).vec[0] ||
        null,
      forType:
        Option.fromFields<StructTag>(
          `0x6adaf7f9c1f7ae68b96dc85f5b069f4a6aabc748d8d741184ca5479fb4466bae::struct_tag::StructTag`,
          fields.for_type,
        ).vec[0] || null,
      amountEach: BigInt(fields.amount_each),
      quantity: fields.quantity,
      expiryMs: BigInt(fields.expiry_ms),
    });
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): ItemOffer {
    if (!isItemOffer(item.type)) {
      throw new Error("not a ItemOffer type");
    }
    const { typeArgs } = parseTypeName(item.type);

    return new ItemOffer(typeArgs[0], {
      id: item.fields.id.id,
      sendTo: `0x${item.fields.send_to}`,
      claim:
        item.fields.claim !== null
          ? Option.fromFieldsWithTypes<Claim>({
              type:
                "0x1::option::Option<" +
                `0x5004aaaf81e51ffc51c4e417e0009017eacbc8d4026417a4195a96852fb9e1cd::claim::Claim<${typeArgs[0]}>` +
                ">",
              fields: { vec: [item.fields.claim] },
            }).vec[0]
          : null,
      forId:
        item.fields.for_id !== null
          ? Option.fromFieldsWithTypes<ObjectId>({
              type: "0x1::option::Option<" + `0x2::object::ID` + ">",
              fields: { vec: [item.fields.for_id] },
            }).vec[0]
          : null,
      forType:
        item.fields.for_type !== null
          ? Option.fromFieldsWithTypes<StructTag>({
              type:
                "0x1::option::Option<" +
                `0x6adaf7f9c1f7ae68b96dc85f5b069f4a6aabc748d8d741184ca5479fb4466bae::struct_tag::StructTag` +
                ">",
              fields: { vec: [item.fields.for_type] },
            }).vec[0]
          : null,
      amountEach: BigInt(item.fields.amount_each),
      quantity: item.fields.quantity,
      expiryMs: BigInt(item.fields.expiry_ms),
    });
  }

  static fromBcs(
    typeArg: Type,
    data: Uint8Array | string,
    encoding?: Encoding,
  ): ItemOffer {
    return ItemOffer.fromFields(
      typeArg,
      bcs.de([ItemOffer.$typeName, typeArg], data, encoding),
    );
  }

  static fromSuiParsedData(content: SuiParsedData) {
    if (content.dataType !== "moveObject") {
      throw new Error("not an object");
    }
    if (!isItemOffer(content.type)) {
      throw new Error(
        `object at ${content.fields.id} is not a ItemOffer object`,
      );
    }
    return ItemOffer.fromFieldsWithTypes(content);
  }

  static async fetch(
    provider: JsonRpcProvider,
    id: ObjectId,
  ): Promise<ItemOffer> {
    const res = await provider.getObject({
      id,
      options: { showContent: true },
    });
    if (res.error) {
      throw new Error(
        `error fetching ItemOffer object at id ${id}: ${res.error.code}`,
      );
    }
    if (
      res.data?.content?.dataType !== "moveObject" ||
      !isItemOffer(res.data.content.type)
    ) {
      throw new Error(`object at id ${id} is not a ItemOffer object`);
    }
    return ItemOffer.fromFieldsWithTypes(res.data.content);
  }
}
