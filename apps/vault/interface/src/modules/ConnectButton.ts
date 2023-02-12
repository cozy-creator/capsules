export function ConnectButton(context: Context) {
  return `
    ${
      context.isConnected
        ? `<button type="button" class="btn btn-danger" id="disconnectBtn">
                Disconnect
            </button>`
        : `<button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#connectModal">
                Connect wallet
            </button>`
    }
    `;
}
