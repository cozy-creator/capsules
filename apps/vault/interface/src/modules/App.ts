import { ConnectButton } from "./ConnectButton";
import { ConnectModal } from "./ConnectModal";

export function App(context: Context) {
  return `
        <div class="my-5">
            <div class="container">
                ${ConnectButton(context)}
                ${ConnectModal(context)}
            </div>
        </div>
    `;
}
