import { bcs } from "./serializer";
import { OUTLAW_SKY_PACKAGE_ID, SCHEMA_ID } from "./config";
import { provider, signer } from "./provider";
import { Serializer } from "./serializer";
import { Model, Schema } from "./sui_odm";
import { JSTypes } from "./validator";

const outlawSchema = {
  name: "ascii",
  image: "ascii",
  power_level: "u64",
} as const;

type Outlaw = JSTypes<typeof outlawSchema>;

bcs.registerStructType('Outlaw', outlawSchema);

const serializer = new Serializer("Outlaw", bcs);
const schema = new Schema(SCHEMA_ID, outlawSchema); 
const model = new Model(schema, OUTLAW_SKY_PACKAGE_ID, provider, signer, serializer, "outlaw_sky");

model.fetch("0xc6c3028a0df2eb49af8cf766971c9b2cf5a8d0c2").then(result =>
    console.log(result)
)

