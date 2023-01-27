import { BCS, BcsConfig } from "@mysten/bcs";
import { string } from "superstruct";

let bcsConfig: BcsConfig = {
  vectorType: "vector",
  addressLength: 20,
  addressEncoding: "hex",
  types: {
    enums: {
      "Option<u64>": {
        none: null,
        some: "u64",
      },
      "Option<ascii>": {
        none: null,
        some: "ascii",
      },
    },
  },
  withPrimitives: true,
};

let bcs = new BCS(bcsConfig);

bcs.registerType(
  "ascii",
  (writer, data: string) => {
    let bytes = new TextEncoder().encode(data);
    if (bytes.length > data.length) throw Error("Not ASCII string");

    writer.writeVec(Array.from(bytes), (w, el: number) => {
      if (el > 127) throw Error("Not ASCII string");
      return w.write8(el);
    });

    return writer;
  },
  (reader) => {
    let bytes = reader.readBytes(reader.readULEB());
    bytes.forEach((byte) => {
      if (byte > 127) throw Error("Not ASCII string");
    });

    return new TextDecoder("ascii").decode(bytes);
  },
  (value) => typeof value == "string"
);

bcs.registerType(
  "utf8",
  (writer, data: string) => {
    let bytes = new TextEncoder().encode(data);
    writer.writeVec(Array.from(bytes), (w, el) => w.write8(el));
    return writer;
  },
  (reader) => {
    let bytes = reader.readBytes(reader.readULEB());
    return new TextDecoder("utf8").decode(bytes);
  },
  (value) => typeof value == "string"
);


export class Serializer {
    type: string;
    baseSerializer: BCS;

    constructor(type: string, baseSerializer:any) {
        this.type = type;
        this.baseSerializer = baseSerializer;
    }

    public serialize(data: object){
        return Array.from(this.baseSerializer.ser(this.type, data).toBytes())
    }

    public deserialize(data: number[]) {
        return this.baseSerializer.de(this.type, new Uint8Array(data))
    }
}
