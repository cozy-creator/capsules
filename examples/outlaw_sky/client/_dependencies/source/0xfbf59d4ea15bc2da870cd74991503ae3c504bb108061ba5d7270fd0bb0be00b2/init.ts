import * as counter from "./counter/structs"
import * as immutable from "./immutable/structs"
import * as map from "./map/structs"
import * as probabilityDistribution from "./probability-distribution/structs"
import * as structTag from "./struct-tag/structs"
import * as typedId from "./typed-id/structs"
import * as vecSet2 from "./vec-set2/structs"
import { StructClassLoader } from "../../../_framework/loader"

export function registerClasses(loader: StructClassLoader) {
    loader.register(counter.Counter)
    loader.register(structTag.StructTag)
    loader.register(typedId.TypedID)
    loader.register(immutable.Immutable)
    loader.register(map.Iter)
    loader.register(map.Map)
    loader.register(probabilityDistribution.ProbabilityDistribution)
    loader.register(vecSet2.VecSet)
}
