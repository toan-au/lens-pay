import '../style.css'
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { createRouter, createWebHistory } from 'vue-router'
import App from '../App.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: () => import('../views/HomeView.vue') },
    { path: '/payments/new', component: () => import('../views/NewPaymentView.vue') },
    { path: '/payments/:uid', component: () => import('../views/PaymentDetailView.vue') },
  ],
})

const pinia = createPinia()

createApp(App)
  .use(router)
  .use(pinia)
  .mount('#app')
