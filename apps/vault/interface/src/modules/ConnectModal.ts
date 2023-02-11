export function ConnectModal({ wallets }: { wallets: { name: string; icon: string }[] }) {
  return `
    <div class="modal fade" id="connectModal" tabindex="-1" aria-labelledby="connectModal" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
            <div class="modal-header">
                <h1 class="modal-title fs-5" id="connectModal">Connect wallet</h1>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                ${wallets
                  .map((wallet) => {
                    return `
                        <btn id="${wallet.name.replaceAll(
                          " ",
                          "-"
                        )}" class="btn my-2 btn-light d-flex justify-content-between align-items-center">
                            <span>${wallet.name}</span>
                            <img src="${wallet.icon}" class="ms-auto" width="30px" />
                        </btn>
                    `;
                  })
                  .join("")}
            </div>
            </div>
        </div>
    </div>
    `;
}
