import * as package_1 from "../_dependencies/source/0x1/init";
import * as package_6adaf7f9c1f7ae68b96dc85f5b069f4a6aabc748d8d741184ca5479fb4466bae from "../_dependencies/source/0x6adaf7f9c1f7ae68b96dc85f5b069f4a6aabc748d8d741184ca5479fb4466bae/init";
import * as package_77e53a48851512fe5707346cf90f85ae0c46b6b527b0fa04935940b0e2f38b42 from "../economy/init";
import * as package_9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a from "../ownership/init";
import * as package_2 from "../sui/init";
import { structClassLoaderSource as structClassLoader } from "./loader";

let initialized = false;
export function initLoaderIfNeeded() {
  if (initialized) {
    return;
  }
  initialized = true;
  package_1.registerClasses(structClassLoader);
  package_2.registerClasses(structClassLoader);
  package_6adaf7f9c1f7ae68b96dc85f5b069f4a6aabc748d8d741184ca5479fb4466bae.registerClasses(
    structClassLoader,
  );
  package_77e53a48851512fe5707346cf90f85ae0c46b6b527b0fa04935940b0e2f38b42.registerClasses(
    structClassLoader,
  );
  package_9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a.registerClasses(
    structClassLoader,
  );
}
