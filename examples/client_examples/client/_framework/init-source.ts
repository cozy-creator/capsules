import * as package_1 from "../_dependencies/source/0x1/init";
import * as package_2 from "../_dependencies/source/0x2/init";
import * as package_fcb0f4008277fc0703d09b7e1245918ce5c9b6f9f65a42eed806430903d72946 from "../_dependencies/source/0xfcb0f4008277fc0703d09b7e1245918ce5c9b6f9f65a42eed806430903d72946/init";
import * as package_c5eb31472393e288d757e8837fc54364487ae649e4abca380de1046e546517bd from "../capsule-baby/init";
import * as package_f167c2f8449be4da16dcf9633206228068d672f2dd2d8d8d06c5cac90dc3d1ac from "../ownership/init";
import { structClassLoaderSource as structClassLoader } from "./loader";

let initialized = false;
export function initLoaderIfNeeded() {
  if (initialized) {
    return;
  }
  initialized = true;
  package_1.registerClasses(structClassLoader);
  package_2.registerClasses(structClassLoader);
  package_c5eb31472393e288d757e8837fc54364487ae649e4abca380de1046e546517bd.registerClasses(
    structClassLoader
  );
  package_f167c2f8449be4da16dcf9633206228068d672f2dd2d8d8d06c5cac90dc3d1ac.registerClasses(
    structClassLoader
  );
  package_fcb0f4008277fc0703d09b7e1245918ce5c9b6f9f65a42eed806430903d72946.registerClasses(
    structClassLoader
  );
}
