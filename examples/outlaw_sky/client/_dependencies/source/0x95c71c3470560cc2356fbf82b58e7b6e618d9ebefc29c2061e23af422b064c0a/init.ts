import * as data from "./data/structs"
import * as schema from "./schema/structs"
import { StructClassLoader } from "../../../_framework/loader"

export function registerClasses(loader: StructClassLoader) {
    loader.register(schema.Key)
    loader.register(data.Key)
    loader.register(data.WRITE)
}
