import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { createRouter, createWebHistory } from 'vue-router'
import App from '../App.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: []
})

const pinia = createPinia()

createApp(App)
  .use(router)
  .use(pinia)
  .mount('#app')
