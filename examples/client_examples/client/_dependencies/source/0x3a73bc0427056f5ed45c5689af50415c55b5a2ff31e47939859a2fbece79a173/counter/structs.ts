import { bcsSource as bcs } from "../../../../_framework/bcs";
import {
  FieldsWithTypes,
  Type,
  parseTypeName,
} from "../../../../_framework/util";
import { UID } from "../../0x2/object/structs";
import { Encoding } from "@mysten/bcs";
import { JsonRpcProvider, ObjectId, SuiParsedData } from "@mysten/sui.js";

/* ============================== Counter =============================== */

bcs.registerStructType(
  "0x3a73bc0427056f5ed45c5689af50415c55b5a2ff31e47939859a2fbece79a173::counter::Counter<T>",
  {
    id: `0x2::object::UID`,
    value: `u256`,
  }
);

export function isCounter(type: Type): boolean {
  return type.startsWith(
    "0x3a73bc0427056f5ed45c5689af50415c55b5a2ff31e47939859a2fbece79a173::counter::Counter<"
  );
}

export interface CounterFields {
  id: ObjectId;
  value: bigint;
}

export class Counter {
  static readonly $typeName =
    "0x3a73bc0427056f5ed45c5689af50415c55b5a2ff31e47939859a2fbece79a173::counter::Counter";
  static readonly $numTypeParams = 1;

  readonly $typeArg: Type;

  readonly id: ObjectId;
  readonly value: bigint;

  constructor(typeArg: Type, fields: CounterFields) {
    this.$typeArg = typeArg;

    this.id = fields.id;
    this.value = fields.value;
  }

  static fromFields(typeArg: Type, fields: Record<string, any>): Counter {
    return new Counter(typeArg, {
      id: UID.fromFields(fields.id).id,
      value: BigInt(fields.value),
    });
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): Counter {
    if (!isCounter(item.type)) {
      throw new Error("not a Counter type");
    }
    const { typeArgs } = parseTypeName(item.type);

    return new Counter(typeArgs[0], {
      id: item.fields.id.id,
      value: BigInt(item.fields.value),
    });
  }

  static fromBcs(
    typeArg: Type,
    data: Uint8Array | string,
    encoding?: Encoding
  ): Counter {
    return Counter.fromFields(
      typeArg,
      bcs.de([Counter.$typeName, typeArg], data, encoding)
    );
  }

  static fromSuiParsedData(content: SuiParsedData) {
    if (content.dataType !== "moveObject") {
      throw new Error("not an object");
    }
    if (!isCounter(content.type)) {
      throw new Error(`object at ${content.fields.id} is not a Counter object`);
    }
    return Counter.fromFieldsWithTypes(content);
  }

  static async fetch(
    provider: JsonRpcProvider,
    id: ObjectId
  ): Promise<Counter> {
    const res = await provider.getObject({
      id,
      options: { showContent: true },
    });
    if (res.error) {
      throw new Error(
        `error fetching Counter object at id ${id}: ${res.error.code}`
      );
    }
    if (
      res.data?.content?.dataType !== "moveObject" ||
      !isCounter(res.data.content.type)
    ) {
      throw new Error(`object at id ${id} is not a Counter object`);
    }
    return Counter.fromFieldsWithTypes(res.data.content);
  }
}
