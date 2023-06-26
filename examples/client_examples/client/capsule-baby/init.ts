import * as capsuleBaby from "./capsule-baby/structs";
import { StructClassLoader } from "../_framework/loader";

export function registerClasses(loader: StructClassLoader) {
  loader.register(capsuleBaby.Witness);
  loader.register(capsuleBaby.CAPSULE_BABY);
  loader.register(capsuleBaby.CapsuleBaby);
  loader.register(capsuleBaby.EDITOR);
}
