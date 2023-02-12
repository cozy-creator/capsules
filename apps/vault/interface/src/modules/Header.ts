import { HeaderButtons } from "./HeaderButtons";

export function Header(context: Context) {
  return `
        <div class="d-flex justify-content-between">
            <div>
            ${
              context.isConnected
                ? `<span>
                        <strong>Wallet</strong>: ${context.account}
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
