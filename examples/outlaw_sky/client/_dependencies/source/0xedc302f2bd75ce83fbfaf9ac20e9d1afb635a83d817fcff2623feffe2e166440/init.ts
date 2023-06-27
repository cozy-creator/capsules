import * as simpleTransfer from "./simple-transfer/structs";
import { StructClassLoader } from "../../../_framework/loader";

export function registerClasses(loader: StructClassLoader) {
  loader.register(simpleTransfer.SimpleTransfer);
}
