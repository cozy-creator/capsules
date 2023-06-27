import { ID, UID } from "../../_dependencies/source/0x2/object/structs";
import { bcsSource as bcs } from "../../_framework/bcs";
import { FieldsWithTypes, Type } from "../../_framework/util";
import { Encoding } from "@mysten/bcs";
import { JsonRpcProvider, ObjectId, SuiParsedData } from "@mysten/sui.js";

/* ============================== PublishReceipt =============================== */

bcs.registerStructType(
  "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::publish_receipt::PublishReceipt",
  {
    id: `0x2::object::UID`,
    package: `0x2::object::ID`,
  }
);

export function isPublishReceipt(type: Type): boolean {
  return (
    type ===
    "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::publish_receipt::PublishReceipt"
  );
}

export interface PublishReceiptFields {
  id: ObjectId;
  package: ObjectId;
}

export class PublishReceipt {
  static readonly $typeName =
    "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::publish_receipt::PublishReceipt";
  static readonly $numTypeParams = 0;

  readonly id: ObjectId;
  readonly package: ObjectId;

  constructor(fields: PublishReceiptFields) {
    this.id = fields.id;
    this.package = fields.package;
  }

  static fromFields(fields: Record<string, any>): PublishReceipt {
    return new PublishReceipt({
      id: UID.fromFields(fields.id).id,
      package: ID.fromFields(fields.package).bytes,
    });
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): PublishReceipt {
    if (!isPublishReceipt(item.type)) {
      throw new Error("not a PublishReceipt type");
    }
    return new PublishReceipt({
      id: item.fields.id.id,
      package: item.fields.package,
    });
  }

  static fromBcs(
    data: Uint8Array | string,
    encoding?: Encoding
  ): PublishReceipt {
    return PublishReceipt.fromFields(
      bcs.de([PublishReceipt.$typeName], data, encoding)
    );
  }

  static fromSuiParsedData(content: SuiParsedData) {
    if (content.dataType !== "moveObject") {
      throw new Error("not an object");
    }
    if (!isPublishReceipt(content.type)) {
      throw new Error(
        `object at ${content.fields.id} is not a PublishReceipt object`
      );
    }
    return PublishReceipt.fromFieldsWithTypes(content);
  }

  static async fetch(
    provider: JsonRpcProvider,
    id: ObjectId
  ): Promise<PublishReceipt> {
    const res = await provider.getObject({
      id,
      options: { showContent: true },
    });
    if (res.error) {
      throw new Error(
        `error fetching PublishReceipt object at id ${id}: ${res.error.code}`
      );
    }
    if (
      res.data?.content?.dataType !== "moveObject" ||
      !isPublishReceipt(res.data.content.type)
    ) {
      throw new Error(`object at id ${id} is not a PublishReceipt object`);
    }
    return PublishReceipt.fromFieldsWithTypes(res.data.content);
  }
}
