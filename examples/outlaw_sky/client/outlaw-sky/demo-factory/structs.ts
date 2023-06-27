import { String } from "../../_dependencies/source/0x1/string/structs";
import { ID, UID } from "../../_dependencies/source/0x2/object/structs";
import { Url } from "../../_dependencies/source/0x2/url/structs";
import { VecMap } from "../../_dependencies/source/0x2/vec-map/structs";
import { bcsSource as bcs } from "../../_framework/bcs";
import { FieldsWithTypes, Type } from "../../_framework/util";
import { Encoding } from "@mysten/bcs";
import { JsonRpcProvider, ObjectId, SuiParsedData } from "@mysten/sui.js";

/* ============================== MetadataUpdated =============================== */

bcs.registerStructType(
  "0x5090ae8a72d892672043a3a4998dbb09e143f87567d0c5a4130b3cf212e06e94::demo_factory::MetadataUpdated",
  {
    for: `0x2::object::ID`,
    metadata: `0x5090ae8a72d892672043a3a4998dbb09e143f87567d0c5a4130b3cf212e06e94::demo_factory::OutlawMetadata`,
  }
);

export function isMetadataUpdated(type: Type): boolean {
  return (
    type ===
    "0x5090ae8a72d892672043a3a4998dbb09e143f87567d0c5a4130b3cf212e06e94::demo_factory::MetadataUpdated"
  );
}

export interface MetadataUpdatedFields {
  for: ObjectId;
  metadata: OutlawMetadata;
}

export class MetadataUpdated {
  static readonly $typeName =
    "0x5090ae8a72d892672043a3a4998dbb09e143f87567d0c5a4130b3cf212e06e94::demo_factory::MetadataUpdated";
  static readonly $numTypeParams = 0;

  readonly for: ObjectId;
  readonly metadata: OutlawMetadata;

  constructor(fields: MetadataUpdatedFields) {
    this.for = fields.for;
    this.metadata = fields.metadata;
  }

  static fromFields(fields: Record<string, any>): MetadataUpdated {
    return new MetadataUpdated({
      for: ID.fromFields(fields.for).bytes,
      metadata: OutlawMetadata.fromFields(fields.metadata),
    });
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): MetadataUpdated {
    if (!isMetadataUpdated(item.type)) {
      throw new Error("not a MetadataUpdated type");
    }
    return new MetadataUpdated({
      for: item.fields.for,
      metadata: OutlawMetadata.fromFieldsWithTypes(item.fields.metadata),
    });
  }

  static fromBcs(
    data: Uint8Array | string,
    encoding?: Encoding
  ): MetadataUpdated {
    return MetadataUpdated.fromFields(
      bcs.de([MetadataUpdated.$typeName], data, encoding)
    );
  }
}

/* ============================== Outlaw =============================== */

bcs.registerStructType(
  "0x5090ae8a72d892672043a3a4998dbb09e143f87567d0c5a4130b3cf212e06e94::demo_factory::Outlaw",
  {
    id: `0x2::object::UID`,
    name: `0x1::string::String`,
    description: `0x1::string::String`,
    url: `0x2::url::Url`,
  }
);

export function isOutlaw(type: Type): boolean {
  return (
    type ===
    "0x5090ae8a72d892672043a3a4998dbb09e143f87567d0c5a4130b3cf212e06e94::demo_factory::Outlaw"
  );
}

export interface OutlawFields {
  id: ObjectId;
  name: string;
  description: string;
  url: string;
}

export class Outlaw {
  static readonly $typeName =
    "0x5090ae8a72d892672043a3a4998dbb09e143f87567d0c5a4130b3cf212e06e94::demo_factory::Outlaw";
  static readonly $numTypeParams = 0;

  readonly id: ObjectId;
  readonly name: string;
  readonly description: string;
  readonly url: string;

  constructor(fields: OutlawFields) {
    this.id = fields.id;
    this.name = fields.name;
    this.description = fields.description;
    this.url = fields.url;
  }

  static fromFields(fields: Record<string, any>): Outlaw {
    return new Outlaw({
      id: UID.fromFields(fields.id).id,
      name: new TextDecoder()
        .decode(Uint8Array.from(String.fromFields(fields.name).bytes))
        .toString(),
      description: new TextDecoder()
        .decode(Uint8Array.from(String.fromFields(fields.description).bytes))
        .toString(),
      url: Url.fromFields(fields.url).url,
    });
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): Outlaw {
    if (!isOutlaw(item.type)) {
      throw new Error("not a Outlaw type");
    }
    return new Outlaw({
      id: item.fields.id.id,
      name: item.fields.name,
      description: item.fields.description,
      url: item.fields.url,
    });
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): Outlaw {
    return Outlaw.fromFields(bcs.de([Outlaw.$typeName], data, encoding));
  }

  static fromSuiParsedData(content: SuiParsedData) {
    if (content.dataType !== "moveObject") {
      throw new Error("not an object");
    }
    if (!isOutlaw(content.type)) {
      throw new Error(`object at ${content.fields.id} is not a Outlaw object`);
    }
    return Outlaw.fromFieldsWithTypes(content);
  }

  static async fetch(provider: JsonRpcProvider, id: ObjectId): Promise<Outlaw> {
    const res = await provider.getObject({
      id,
      options: { showContent: true },
    });
    if (res.error) {
      throw new Error(
        `error fetching Outlaw object at id ${id}: ${res.error.code}`
      );
    }
    if (
      res.data?.content?.dataType !== "moveObject" ||
      !isOutlaw(res.data.content.type)
    ) {
      throw new Error(`object at id ${id} is not a Outlaw object`);
    }
    return Outlaw.fromFieldsWithTypes(res.data.content);
  }
}

/* ============================== OutlawMetadata =============================== */

bcs.registerStructType(
  "0x5090ae8a72d892672043a3a4998dbb09e143f87567d0c5a4130b3cf212e06e94::demo_factory::OutlawMetadata",
  {
    attributes: `0x2::vec_map::VecMap<0x1::string::String, 0x1::string::String>`,
    url: `0x1::string::String`,
  }
);

export function isOutlawMetadata(type: Type): boolean {
  return (
    type ===
    "0x5090ae8a72d892672043a3a4998dbb09e143f87567d0c5a4130b3cf212e06e94::demo_factory::OutlawMetadata"
  );
}

export interface OutlawMetadataFields {
  attributes: VecMap<string, string>;
  url: string;
}

export class OutlawMetadata {
  static readonly $typeName =
    "0x5090ae8a72d892672043a3a4998dbb09e143f87567d0c5a4130b3cf212e06e94::demo_factory::OutlawMetadata";
  static readonly $numTypeParams = 0;

  readonly attributes: VecMap<string, string>;
  readonly url: string;

  constructor(fields: OutlawMetadataFields) {
    this.attributes = fields.attributes;
    this.url = fields.url;
  }

  static fromFields(fields: Record<string, any>): OutlawMetadata {
    return new OutlawMetadata({
      attributes: VecMap.fromFields<string, string>(
        [`0x1::string::String`, `0x1::string::String`],
        fields.attributes
      ),
      url: new TextDecoder()
        .decode(Uint8Array.from(String.fromFields(fields.url).bytes))
        .toString(),
    });
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): OutlawMetadata {
    if (!isOutlawMetadata(item.type)) {
      throw new Error("not a OutlawMetadata type");
    }
    return new OutlawMetadata({
      attributes: VecMap.fromFieldsWithTypes<string, string>(
        item.fields.attributes
      ),
      url: item.fields.url,
    });
  }

  static fromBcs(
    data: Uint8Array | string,
    encoding?: Encoding
  ): OutlawMetadata {
    return OutlawMetadata.fromFields(
      bcs.de([OutlawMetadata.$typeName], data, encoding)
    );
  }
}
