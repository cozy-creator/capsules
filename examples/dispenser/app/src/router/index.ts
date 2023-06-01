import { createRouter, createWebHistory } from "vue-router";
import CreateDispenser from "@/views/Create.vue";
import ViewDispenser from "@/views/View.vue";
import MintDispenser from "@/views/Mint.vue";

export const router = createRouter({
  routes: [
    { path: "/dispenser/create", component: CreateDispenser },
    { path: "/dispenser/view", component: ViewDispenser },
    { path: "/dispenser/mint", component: MintDispenser },
  ],

  history: createWebHistory(process.env.BASE_URL),
});
