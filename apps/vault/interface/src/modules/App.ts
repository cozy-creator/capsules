import { ConnectModal } from "./ConnectModal";
import { Header } from "./Header";

export function App(context: Context) {
  return `
        <div class="my-5">
            <div class="container">
                ${Header(context)}
                ${ConnectModal(context)}
            </div>
        </div>
    `;
}
