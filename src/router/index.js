import AppLayout from '@/layout/AppLayout.vue';
import { createRouter, createWebHistory } from 'vue-router';
import { useSessionStore } from '@/stores/session.js';

const router = createRouter({
    history: createWebHistory(),
    routes: [
        // Rutas protegidas
        {
            path: '/',
            component: AppLayout,
            meta: { requiresAuth: true },
            children: [
                {
                    path: '/',
                    name: 'dashboard',
                    component: () => import('@/views/Dashboard.vue'),
                    meta: { requiresAuth: true }
                },
                {
                    path: '/profile',
                    name: 'profile',
                    component: () => import('@/views/modules/Profile/index.vue'),
                    meta: { requiresAuth: true }
                },
                {
                    path: '/charts',
                    name: 'charts',
                    component: () => import('@/views/modules/Charts/index.vue'),
                    meta: { requiresAuth: true }
                },
                {
                    path: '/categories',
                    name: 'categories',
                    component: () => import('@/views/modules/Categories/index.vue'),
                },
                {
                    path: '/levels',
                    name: 'levels',
                    component: () => import('@/views/modules/Levels/index.vue'),
                },
                {
                    path: '/banks',
                    name: 'banks',
                    component: () => import('@/views/modules/Banks/index.vue'),
                },
            ]
        },
        // Rutas públicas
        {
            path: '/auth',
            name: 'login',
            component: () => import('@/views/pages/auth/Auth.vue'),
            meta: { redirectIfAuth: true } // Redirigir si ya está autenticado
        },
        {
            path: '/notfound',
            name: 'notfound',
            component: () => import('@/views/pages/NotFound.vue')
        },
        {
            path: '/access-denied',
            name: 'accessDenied',
            component: () => import('@/views/pages/Access.vue')
        },
        {
            path: '/error',
            name: 'error',
            component: () => import('@/views/pages/Error.vue')
        },
        {
            path: '/landing',
            name: 'landing',
            component: () => import('@/views/pages/Landing.vue')
        },
        {
            path: '/empty',
            name: 'empty',
            component: () => import('@/views/pages/Empty.vue')
        },
        // Ruta catch-all para 404
        {
            path: '/:pathMatch(.*)*',
            redirect: '/notfound'
        }
    ]
});

// Guard de navegación global mejorado
router.beforeEach(async (to, from, next) => {
    const sessionStore = useSessionStore();

    console.log('🛡️ Navigation guard ejecutado:', {
        to: to.path,
        from: from.path,
        initialized: sessionStore.initialized,
        isAuthenticated: sessionStore.isAuthenticated,
        userEmail: sessionStore.userEmail
    });

    // **CAMBIO CRÍTICO:** No llamar initializeAuth aquí
    // Solo esperar a que se inicialice si no está listo
    let attempts = 0;
    const maxAttempts = 30; // 3 segundos máximo

    while (!sessionStore.initialized && attempts < maxAttempts) {
        console.log(`⏳ Esperando inicialización... intento ${attempts + 1}/${maxAttempts}`);
        await new Promise(resolve => setTimeout(resolve, 100));
        attempts++;
    }

    if (!sessionStore.initialized) {
        console.warn('⚠️ Timeout esperando inicialización. Continuando con estado actual...');
        console.warn('Estado actual:', {
            user: !!sessionStore.user,
            initialized: sessionStore.initialized
        });
    }

    const isAuthenticated = sessionStore.isAuthenticated;
    const requiresAuth = to.matched.some(record => record.meta.requiresAuth);
    const redirectIfAuth = to.matched.some(record => record.meta.redirectIfAuth);

    console.log('🔍 Estado de navegación:', {
        to: to.path,
        isAuthenticated,
        requiresAuth,
        redirectIfAuth,
        userEmail: sessionStore.userEmail,
        hasUser: !!sessionStore.user
    });

    // Si la ruta requiere autenticación y el usuario no está autenticado
    if (requiresAuth && !isAuthenticated) {
        console.log('🚫 Redirecting to auth - user not authenticated');
        next('/auth');
        return;
    }

    // Si el usuario está autenticado y trata de ir a auth, redirigir al dashboard
    if (redirectIfAuth && isAuthenticated) {
        console.log('✅ Redirecting to dashboard - user already authenticated');
        next('/');
        return;
    }

    // Si todo está bien, continuar
    console.log('✅ Navigation allowed:', to.path);
    next();
});

export default router;
