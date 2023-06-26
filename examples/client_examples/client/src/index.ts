import { agentSigner, ownerSigner } from "./config";
import {
  editBabyWithEmptyAction,
  editBabyWithGeneralAction,
  editBabyWithObjectAction,
  editBabyWithTypeAction,
} from "./person";

// editBabyWithGeneralAction({ owner: ownerSigner, agent: agentSigner });
// editBabyWithTypeAction({ owner: ownerSigner, agent: agentSigner });
// editBabyWithObjectAction({ owner: ownerSigner, agent: agentSigner });
editBabyWithEmptyAction({ owner: ownerSigner, agent: agentSigner });
