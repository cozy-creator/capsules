import { bcsSource as bcs } from "../../_framework/bcs";
import { FieldsWithTypes, Type, parseTypeName } from "../../_framework/util";
import { Balance } from "../../sui/balance/structs";
import { LinkedTable } from "../../sui/linked-table/structs";
import { Encoding } from "@mysten/bcs";

/* ============================== Queue =============================== */

bcs.registerStructType(
  "0xf0ac6529d000107a6e44a7e5922d3f54142ecbc1e7b44c515c2c844b325d08bc::queue::Queue<T>",
  {
    incoming: `0x2::linked_table::LinkedTable<address, 0x2::balance::Balance<T>>`,
    reserve: `0x2::balance::Balance<T>`,
    outgoing: `0x2::linked_table::LinkedTable<address, 0x2::balance::Balance<T>>`,
  },
);

export function isQueue(type: Type): boolean {
  return type.startsWith(
    "0xf0ac6529d000107a6e44a7e5922d3f54142ecbc1e7b44c515c2c844b325d08bc::queue::Queue<",
  );
}

export interface QueueFields {
  incoming: LinkedTable<string>;
  reserve: Balance;
  outgoing: LinkedTable<string>;
}

export class Queue {
  static readonly $typeName =
    "0xf0ac6529d000107a6e44a7e5922d3f54142ecbc1e7b44c515c2c844b325d08bc::queue::Queue";
  static readonly $numTypeParams = 1;

  readonly $typeArg: Type;

  readonly incoming: LinkedTable<string>;
  readonly reserve: Balance;
  readonly outgoing: LinkedTable<string>;

  constructor(typeArg: Type, fields: QueueFields) {
    this.$typeArg = typeArg;

    this.incoming = fields.incoming;
    this.reserve = fields.reserve;
    this.outgoing = fields.outgoing;
  }

  static fromFields(typeArg: Type, fields: Record<string, any>): Queue {
    return new Queue(typeArg, {
      incoming: LinkedTable.fromFields<string>(
        [`address`, `0x2::balance::Balance<${typeArg}>`],
        fields.incoming,
      ),
      reserve: Balance.fromFields(`${typeArg}`, fields.reserve),
      outgoing: LinkedTable.fromFields<string>(
        [`address`, `0x2::balance::Balance<${typeArg}>`],
        fields.outgoing,
      ),
    });
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): Queue {
    if (!isQueue(item.type)) {
      throw new Error("not a Queue type");
    }
    const { typeArgs } = parseTypeName(item.type);

    return new Queue(typeArgs[0], {
      incoming: LinkedTable.fromFieldsWithTypes<string>(item.fields.incoming),
      reserve: new Balance(`${typeArgs[0]}`, BigInt(item.fields.reserve)),
      outgoing: LinkedTable.fromFieldsWithTypes<string>(item.fields.outgoing),
    });
  }

  static fromBcs(
    typeArg: Type,
    data: Uint8Array | string,
    encoding?: Encoding,
  ): Queue {
    return Queue.fromFields(
      typeArg,
      bcs.de([Queue.$typeName, typeArg], data, encoding),
    );
  }
}
