import * as capsule from "./capsule/structs";
import { StructClassLoader } from "../../../_framework/loader";

export function registerClasses(loader: StructClassLoader) {
  loader.register(capsule.Witness);
  loader.register(capsule.Key);
  loader.register(capsule.Capsule);
}
