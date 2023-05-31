import { createRouter, createWebHistory } from "vue-router";
import CreateDispenser from "@/views/Create.vue";
import ViewDispenser from "@/views/View.vue";

export const router = createRouter({
  routes: [
    { path: "/dispenser/create", component: CreateDispenser },
    { path: "/dispenser/view", component: ViewDispenser },
  ],

  history: createWebHistory(process.env.BASE_URL),
});
