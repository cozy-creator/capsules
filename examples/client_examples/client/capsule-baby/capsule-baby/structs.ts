import { String } from "../../_dependencies/source/0x1/string/structs";
import { UID } from "../../_dependencies/source/0x2/object/structs";
import { bcsSource as bcs } from "../../_framework/bcs";
import { FieldsWithTypes, Type } from "../../_framework/util";
import { Encoding } from "@mysten/bcs";
import { JsonRpcProvider, ObjectId, SuiParsedData } from "@mysten/sui.js";

/* ============================== Witness =============================== */

bcs.registerStructType(
  "0xc5eb31472393e288d757e8837fc54364487ae649e4abca380de1046e546517bd::capsule_baby::Witness",
  {
    dummy_field: `bool`,
  }
);

export function isWitness(type: Type): boolean {
  return (
    type ===
    "0xc5eb31472393e288d757e8837fc54364487ae649e4abca380de1046e546517bd::capsule_baby::Witness"
  );
}

export interface WitnessFields {
  dummyField: boolean;
}

export class Witness {
  static readonly $typeName =
    "0xc5eb31472393e288d757e8837fc54364487ae649e4abca380de1046e546517bd::capsule_baby::Witness";
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

/* ============================== CAPSULE_BABY =============================== */

bcs.registerStructType(
  "0xc5eb31472393e288d757e8837fc54364487ae649e4abca380de1046e546517bd::capsule_baby::CAPSULE_BABY",
  {
    dummy_field: `bool`,
  }
);

export function isCAPSULE_BABY(type: Type): boolean {
  return (
    type ===
    "0xc5eb31472393e288d757e8837fc54364487ae649e4abca380de1046e546517bd::capsule_baby::CAPSULE_BABY"
  );
}

export interface CAPSULE_BABYFields {
  dummyField: boolean;
}

export class CAPSULE_BABY {
  static readonly $typeName =
    "0xc5eb31472393e288d757e8837fc54364487ae649e4abca380de1046e546517bd::capsule_baby::CAPSULE_BABY";
  static readonly $numTypeParams = 0;

  readonly dummyField: boolean;

  constructor(dummyField: boolean) {
    this.dummyField = dummyField;
  }

  static fromFields(fields: Record<string, any>): CAPSULE_BABY {
    return new CAPSULE_BABY(fields.dummy_field);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): CAPSULE_BABY {
    if (!isCAPSULE_BABY(item.type)) {
      throw new Error("not a CAPSULE_BABY type");
    }
    return new CAPSULE_BABY(item.fields.dummy_field);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): CAPSULE_BABY {
    return CAPSULE_BABY.fromFields(
      bcs.de([CAPSULE_BABY.$typeName], data, encoding)
    );
  }
}

/* ============================== CapsuleBaby =============================== */

bcs.registerStructType(
  "0xc5eb31472393e288d757e8837fc54364487ae649e4abca380de1046e546517bd::capsule_baby::CapsuleBaby",
  {
    id: `0x2::object::UID`,
    name: `0x1::string::String`,
  }
);

export function isCapsuleBaby(type: Type): boolean {
  return (
    type ===
    "0xc5eb31472393e288d757e8837fc54364487ae649e4abca380de1046e546517bd::capsule_baby::CapsuleBaby"
  );
}

export interface CapsuleBabyFields {
  id: ObjectId;
  name: string;
}

export class CapsuleBaby {
  static readonly $typeName =
    "0xc5eb31472393e288d757e8837fc54364487ae649e4abca380de1046e546517bd::capsule_baby::CapsuleBaby";
  static readonly $numTypeParams = 0;

  readonly id: ObjectId;
  readonly name: string;

  constructor(fields: CapsuleBabyFields) {
    this.id = fields.id;
    this.name = fields.name;
  }

  static fromFields(fields: Record<string, any>): CapsuleBaby {
    return new CapsuleBaby({
      id: UID.fromFields(fields.id).id,
      name: new TextDecoder()
        .decode(Uint8Array.from(String.fromFields(fields.name).bytes))
        .toString(),
    });
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): CapsuleBaby {
    if (!isCapsuleBaby(item.type)) {
      throw new Error("not a CapsuleBaby type");
    }
    return new CapsuleBaby({ id: item.fields.id.id, name: item.fields.name });
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): CapsuleBaby {
    return CapsuleBaby.fromFields(
      bcs.de([CapsuleBaby.$typeName], data, encoding)
    );
  }

  static fromSuiParsedData(content: SuiParsedData) {
    if (content.dataType !== "moveObject") {
      throw new Error("not an object");
    }
    if (!isCapsuleBaby(content.type)) {
      throw new Error(
        `object at ${content.fields.id} is not a CapsuleBaby object`
      );
    }
    return CapsuleBaby.fromFieldsWithTypes(content);
  }

  static async fetch(
    provider: JsonRpcProvider,
    id: ObjectId
  ): Promise<CapsuleBaby> {
    const res = await provider.getObject({
      id,
      options: { showContent: true },
    });
    if (res.error) {
      throw new Error(
        `error fetching CapsuleBaby object at id ${id}: ${res.error.code}`
      );
    }
    if (
      res.data?.content?.dataType !== "moveObject" ||
      !isCapsuleBaby(res.data.content.type)
    ) {
      throw new Error(`object at id ${id} is not a CapsuleBaby object`);
    }
    return CapsuleBaby.fromFieldsWithTypes(res.data.content);
  }
}

/* ============================== EDITOR =============================== */

bcs.registerStructType(
  "0xc5eb31472393e288d757e8837fc54364487ae649e4abca380de1046e546517bd::capsule_baby::EDITOR",
  {
    dummy_field: `bool`,
  }
);

export function isEDITOR(type: Type): boolean {
  return (
    type ===
    "0xc5eb31472393e288d757e8837fc54364487ae649e4abca380de1046e546517bd::capsule_baby::EDITOR"
  );
}

export interface EDITORFields {
  dummyField: boolean;
}

export class EDITOR {
  static readonly $typeName =
    "0xc5eb31472393e288d757e8837fc54364487ae649e4abca380de1046e546517bd::capsule_baby::EDITOR";
  static readonly $numTypeParams = 0;

  readonly dummyField: boolean;

  constructor(dummyField: boolean) {
    this.dummyField = dummyField;
  }

  static fromFields(fields: Record<string, any>): EDITOR {
    return new EDITOR(fields.dummy_field);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): EDITOR {
    if (!isEDITOR(item.type)) {
      throw new Error("not a EDITOR type");
    }
    return new EDITOR(item.fields.dummy_field);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): EDITOR {
    return EDITOR.fromFields(bcs.de([EDITOR.$typeName], data, encoding));
  }
}
