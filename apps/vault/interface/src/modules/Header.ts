import { truncate0x } from "../utils";
import { HeaderButtons } from "./HeaderButtons";

export function Header(context: Context) {
  return `
        <div class="d-flex justify-content-between">
            <div>
            ${
              context.isConnected
                ? `<span>
                        <strong>Wallet</strong>: 
                        <a 
                            class="text-decoration-none" 
                            target="_blank" 
                            href="https://explorer.sui.io/address/${context.account}">
                                ${truncate0x(context.account)}
                        </a>
                    </span>`
                : `<span>
                        Wallet not connected
                    </span>
                `
            }   
            </div>
        
            ${HeaderButtons(context)}
        </div>
    `;
}
