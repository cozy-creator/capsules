export function HeaderButtons(context: Context) {
  return `
    ${
      context.isConnected
        ? `
          <div>
              <button type="button" class="btn btn-sm btn-primary" id="createVaultBtn">
                Create a vault
              </button>

              <button type="button" class="btn btn-sm btn-danger" id="disconnectBtn">
                  Disconnect
              </button>
            </div>`
        : `<button type="button" class="btn btn-sm btn-primary" data-bs-toggle="modal" data-bs-target="#connectModal">
                Connect wallet
            </button>`
    }
    `;
}
