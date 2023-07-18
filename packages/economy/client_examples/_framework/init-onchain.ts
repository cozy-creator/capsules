import * as package_1 from "../_dependencies/onchain/0x1/init";
import * as package_2 from "../sui/init";
import { structClassLoaderOnchain as structClassLoader } from "./loader";

let initialized = false;
export function initLoaderIfNeeded() {
  if (initialized) {
    return;
  }
  initialized = true;
  package_1.registerClasses(structClassLoader);
  package_2.registerClasses(structClassLoader);
}
