import * as package_1 from "../_dependencies/source/0x1/init";
import * as package_2 from "../_dependencies/source/0x2/init";
import * as package_3a73bc0427056f5ed45c5689af50415c55b5a2ff31e47939859a2fbece79a173 from "../_dependencies/source/0x3a73bc0427056f5ed45c5689af50415c55b5a2ff31e47939859a2fbece79a173/init";
import * as package_ef314c6493ec267f9d39bc78895aa30fa254c7fbd49685559cb4d0a98bb9dda6 from "../capsule-baby/init";
import * as package_e94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc from "../ownership/init";
import { structClassLoaderSource as structClassLoader } from "./loader";

let initialized = false;
export function initLoaderIfNeeded() {
  if (initialized) {
    return;
  }
  initialized = true;
  package_1.registerClasses(structClassLoader);
  package_2.registerClasses(structClassLoader);
  package_3a73bc0427056f5ed45c5689af50415c55b5a2ff31e47939859a2fbece79a173.registerClasses(
    structClassLoader
  );
  package_e94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc.registerClasses(
    structClassLoader
  );
  package_ef314c6493ec267f9d39bc78895aa30fa254c7fbd49685559cb4d0a98bb9dda6.registerClasses(
    structClassLoader
  );
}
