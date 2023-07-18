import { bcsSource as bcs } from "../../../../_framework/bcs";
import { FieldsWithTypes, Type } from "../../../../_framework/util";
import { UID } from "../../0x2/object/structs";
import { Encoding } from "@mysten/bcs";
import { JsonRpcProvider, ObjectId, SuiParsedData } from "@mysten/sui.js";

/* ============================== Key =============================== */

bcs.registerStructType(
  "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::person::Key",
  {
    agent: `address`,
  },
);

export function isKey(type: Type): boolean {
  return (
    type ===
    "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::person::Key"
  );
}

export interface KeyFields {
  agent: string;
}

export class Key {
  static readonly $typeName =
    "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::person::Key";
  static readonly $numTypeParams = 0;

  readonly agent: string;

  constructor(agent: string) {
    this.agent = agent;
  }

  static fromFields(fields: Record<string, any>): Key {
    return new Key(`0x${fields.agent}`);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): Key {
    if (!isKey(item.type)) {
      throw new Error("not a Key type");
    }
    return new Key(`0x${item.fields.agent}`);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): Key {
    return Key.fromFields(bcs.de([Key.$typeName], data, encoding));
  }
}

/* ============================== Person =============================== */

bcs.registerStructType(
  "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::person::Person",
  {
    id: `0x2::object::UID`,
    principal: `address`,
    guardian: `address`,
  },
);

export function isPerson(type: Type): boolean {
  return (
    type ===
    "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::person::Person"
  );
}

export interface PersonFields {
  id: ObjectId;
  principal: string;
  guardian: string;
}

export class Person {
  static readonly $typeName =
    "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::person::Person";
  static readonly $numTypeParams = 0;

  readonly id: ObjectId;
  readonly principal: string;
  readonly guardian: string;

  constructor(fields: PersonFields) {
    this.id = fields.id;
    this.principal = fields.principal;
    this.guardian = fields.guardian;
  }

  static fromFields(fields: Record<string, any>): Person {
    return new Person({
      id: UID.fromFields(fields.id).id,
      principal: `0x${fields.principal}`,
      guardian: `0x${fields.guardian}`,
    });
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): Person {
    if (!isPerson(item.type)) {
      throw new Error("not a Person type");
    }
    return new Person({
      id: item.fields.id.id,
      principal: `0x${item.fields.principal}`,
      guardian: `0x${item.fields.guardian}`,
    });
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): Person {
    return Person.fromFields(bcs.de([Person.$typeName], data, encoding));
  }

  static fromSuiParsedData(content: SuiParsedData) {
    if (content.dataType !== "moveObject") {
      throw new Error("not an object");
    }
    if (!isPerson(content.type)) {
      throw new Error(`object at ${content.fields.id} is not a Person object`);
    }
    return Person.fromFieldsWithTypes(content);
  }

  static async fetch(provider: JsonRpcProvider, id: ObjectId): Promise<Person> {
    const res = await provider.getObject({
      id,
      options: { showContent: true },
    });
    if (res.error) {
      throw new Error(
        `error fetching Person object at id ${id}: ${res.error.code}`,
      );
    }
    if (
      res.data?.content?.dataType !== "moveObject" ||
      !isPerson(res.data.content.type)
    ) {
      throw new Error(`object at id ${id} is not a Person object`);
    }
    return Person.fromFieldsWithTypes(res.data.content);
  }
}
