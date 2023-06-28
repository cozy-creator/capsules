import * as demoFactory from "./demo-factory/structs"
import * as outlawSky from "./outlaw-sky/structs"
import * as warship from "./warship/structs"
import { StructClassLoader } from "../_framework/loader"

export function registerClasses(loader: StructClassLoader) {
    loader.register(demoFactory.MetadataUpdated)
    loader.register(demoFactory.Outlaw)
    loader.register(demoFactory.OutlawMetadata)
    loader.register(outlawSky.Outlaw)
    loader.register(outlawSky.Witness)
    loader.register(outlawSky.CREATOR)
    loader.register(outlawSky.OUTLAW_SKY)
    loader.register(outlawSky.USER)
    loader.register(warship.Witness)
    loader.register(warship.Warship)
}
