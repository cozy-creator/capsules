import * as claim from "./claim/structs";
import * as coin23 from "./coin23/structs";
import * as fund from "./fund/structs";
import * as itemOffer from "./item-offer/structs";
import * as payMemo from "./pay-memo/structs";
import * as queue from "./queue/structs";
import { StructClassLoader } from "../_framework/loader";

export function registerClasses(loader: StructClassLoader) {
  loader.register(coin23.Witness);
  loader.register(coin23.FREEZE);
  loader.register(coin23.COIN23);
  loader.register(coin23.Coin23);
  loader.register(coin23.CurrencyControls);
  loader.register(coin23.CurrencyRegistry);
  loader.register(coin23.Hold);
  loader.register(coin23.MERCHANT);
  loader.register(coin23.Rebill);
  loader.register(coin23.TransferFee);
  loader.register(coin23.WITHDRAW);
  loader.register(claim.Claim);
  loader.register(queue.Queue);
  loader.register(fund.Config);
  loader.register(fund.Witness);
  loader.register(fund.Fund);
  loader.register(fund.MANAGE_FUND);
  loader.register(fund.PURCHASE);
  loader.register(fund.REDEEM);
  loader.register(itemOffer.Witness);
  loader.register(itemOffer.ItemOffer);
  loader.register(payMemo.PayMemo);
}
