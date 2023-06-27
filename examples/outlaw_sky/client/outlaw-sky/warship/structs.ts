import { UID } from "../../_dependencies/source/0x2/object/structs";
import { bcsSource as bcs } from "../../_framework/bcs";
import { FieldsWithTypes, Type } from "../../_framework/util";
import { Encoding } from "@mysten/bcs";
import { JsonRpcProvider, ObjectId, SuiParsedData } from "@mysten/sui.js";

/* ============================== Witness =============================== */

bcs.registerStructType(
  "0x5090ae8a72d892672043a3a4998dbb09e143f87567d0c5a4130b3cf212e06e94::warship::Witness",
  {
    dummy_field: `bool`,
  }
);

export function isWitness(type: Type): boolean {
  return (
    type ===
    "0x5090ae8a72d892672043a3a4998dbb09e143f87567d0c5a4130b3cf212e06e94::warship::Witness"
  );
}

export interface WitnessFields {
  dummyField: boolean;
}

export class Witness {
  static readonly $typeName =
    "0x5090ae8a72d892672043a3a4998dbb09e143f87567d0c5a4130b3cf212e06e94::warship::Witness";
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

/* ============================== Warship =============================== */

bcs.registerStructType(
  "0x5090ae8a72d892672043a3a4998dbb09e143f87567d0c5a4130b3cf212e06e94::warship::Warship",
  {
    id: `0x2::object::UID`,
  }
);

export function isWarship(type: Type): boolean {
  return (
    type ===
    "0x5090ae8a72d892672043a3a4998dbb09e143f87567d0c5a4130b3cf212e06e94::warship::Warship"
  );
}

export interface WarshipFields {
  id: ObjectId;
}

export class Warship {
  static readonly $typeName =
    "0x5090ae8a72d892672043a3a4998dbb09e143f87567d0c5a4130b3cf212e06e94::warship::Warship";
  static readonly $numTypeParams = 0;

  readonly id: ObjectId;

  constructor(id: ObjectId) {
    this.id = id;
  }

  static fromFields(fields: Record<string, any>): Warship {
    return new Warship(UID.fromFields(fields.id).id);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): Warship {
    if (!isWarship(item.type)) {
      throw new Error("not a Warship type");
    }
    return new Warship(item.fields.id.id);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): Warship {
    return Warship.fromFields(bcs.de([Warship.$typeName], data, encoding));
  }

  static fromSuiParsedData(content: SuiParsedData) {
    if (content.dataType !== "moveObject") {
      throw new Error("not an object");
    }
    if (!isWarship(content.type)) {
      throw new Error(`object at ${content.fields.id} is not a Warship object`);
    }
    return Warship.fromFieldsWithTypes(content);
  }

  static async fetch(
    provider: JsonRpcProvider,
    id: ObjectId
  ): Promise<Warship> {
    const res = await provider.getObject({
      id,
      options: { showContent: true },
    });
    if (res.error) {
      throw new Error(
        `error fetching Warship object at id ${id}: ${res.error.code}`
      );
    }
    if (
      res.data?.content?.dataType !== "moveObject" ||
      !isWarship(res.data.content.type)
    ) {
      throw new Error(`object at id ${id} is not a Warship object`);
    }
    return Warship.fromFieldsWithTypes(res.data.content);
  }
}
