import '../style.css'
import { createApp, nextTick } from 'vue'
import { createPinia } from 'pinia'
import { createRouter, createWebHistory } from 'vue-router'
import App from '../App.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: () => import('../views/HomeView.vue'), meta: { title: 'Payments' } },
    { path: '/payments/new', component: () => import('../views/NewPaymentView.vue'), meta: { title: 'New payment' } },
    { path: '/payments/:uid', component: () => import('../views/PaymentDetailView.vue'), meta: { title: 'Payment' } },
    { path: '/customers', component: () => import('../views/CustomersView.vue'), meta: { title: 'Customers' } },
    { path: '/customers/:uid', component: () => import('../views/CustomerDetailView.vue'), meta: { title: 'Customer' } },
    { path: '/refunds', component: () => import('../views/RefundsView.vue'), meta: { title: 'Refunds' } },
    { path: '/disputes', component: () => import('../views/DisputesView.vue'), meta: { title: 'Disputes' } },
    { path: '/disputes/:uid', component: () => import('../views/DisputeDetailView.vue'), meta: { title: 'Dispute' } },
    { path: '/webhooks', component: () => import('../views/WebhookEventsView.vue'), meta: { title: 'Webhook events' } },
    { path: '/profile', component: () => import('../views/ProfileView.vue'), meta: { title: 'Profile' } },
  ],
})

// SPA navigation is silent to assistive tech: the URL and DOM change but focus
// and the page title do not. Update the title and move focus to the main region
// after each navigation so screen readers announce the new view.
router.afterEach((to) => {
  const title = to.meta.title as string | undefined
  document.title = title ? `${title} · LensPay` : 'LensPay'
  nextTick(() => {
    const main = document.getElementById('main-content')
    main?.focus()
  })
})

const pinia = createPinia()

createApp(App)
  .use(router)
  .use(pinia)
  .mount('#app')
