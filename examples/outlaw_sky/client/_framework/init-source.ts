import * as package_1 from "../_dependencies/source/0x1/init"
import * as package_2 from "../_dependencies/source/0x2/init"
import * as package_6bdbc56a5fa3783d182bc6f60e8b5216b708de0bf6f5e5ffa3e886fbf5c1a317 from "../_dependencies/source/0x6bdbc56a5fa3783d182bc6f60e8b5216b708de0bf6f5e5ffa3e886fbf5c1a317/init"
import * as package_b8f4b2057dcf971ebd082343462e233c46562d7fbd808472ac978714f296f2e4 from "../_dependencies/source/0xb8f4b2057dcf971ebd082343462e233c46562d7fbd808472ac978714f296f2e4/init"
import * as package_edc302f2bd75ce83fbfaf9ac20e9d1afb635a83d817fcff2623feffe2e166440 from "../_dependencies/source/0xedc302f2bd75ce83fbfaf9ac20e9d1afb635a83d817fcff2623feffe2e166440/init"
import * as package_68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64 from "../outlaw-sky/init"
import * as package_98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96 from "../ownership/init"
import * as package_fbf59d4ea15bc2da870cd74991503ae3c504bb108061ba5d7270fd0bb0be00b2 from "../sui-utils/init"
import { structClassLoaderSource as structClassLoader } from "./loader"

let initialized = false
export function initLoaderIfNeeded() {
    if (initialized) {
        return
    }
    initialized = true
    package_1.registerClasses(structClassLoader)
    package_2.registerClasses(structClassLoader)
    package_68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64.registerClasses(
        structClassLoader
    )
    package_6bdbc56a5fa3783d182bc6f60e8b5216b708de0bf6f5e5ffa3e886fbf5c1a317.registerClasses(
        structClassLoader
    )
    package_98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96.registerClasses(
        structClassLoader
    )
    package_b8f4b2057dcf971ebd082343462e233c46562d7fbd808472ac978714f296f2e4.registerClasses(
        structClassLoader
    )
    package_edc302f2bd75ce83fbfaf9ac20e9d1afb635a83d817fcff2623feffe2e166440.registerClasses(
        structClassLoader
    )
    package_fbf59d4ea15bc2da870cd74991503ae3c504bb108061ba5d7270fd0bb0be00b2.registerClasses(
        structClassLoader
    )
}
