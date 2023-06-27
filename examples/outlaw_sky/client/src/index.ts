import { CREATOR } from "../outlaw-sky/outlaw-sky/structs";
import { adminSigner, agentSigner } from "./config";
import { revokeActionFromOrgRole } from "./organization";

async function main() {
  const OUTLAWYER_ROLE = "OUTLAWYER";
  const OUTLAWYER_R = "OUTLAWYERR";
  const agent = await agentSigner.getAddress();
  const org = "0x84ca23305272e45a049291d8162186384d86913ae341738123fb47e28b06f314";

  // grantOrgActionToRole({ action: CREATOR.$typeName, signer: adminSigner, role: OUTLAWYER_ROLE, org });
  // setOrgRoleForAgent({ agent, signer: adminSigner, role: OUTLAWYER_ROLE, org });
  // revokeActionFromOrgRole({ action: CREATOR.$typeName, org, role: OUTLAWYER_ROLE, signer: adminSigner });
}

main();
