import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
    history: createWebHistory(import.meta.env.BASE_URL),
    routes: [
        {
            path: '/',
            name: 'home',
            component: () => import('@/modules/Home/index.vue'),
            meta: { requiresAuth: true }
        },
        {
            path: '/signin',
            name: 'signin',
            component: () => import('@/modules/Auth/index.vue'),
            meta: { requiresAuth: false }
        },
    ],
})

export default router
