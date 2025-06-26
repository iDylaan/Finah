import '@/assets/styles.scss';

import { createApp } from 'vue'
import App from './App.vue'

import router from './router/index.js'

import { createPinia } from 'pinia'
import { useUIStore } from '@/stores/ui.js'
import { useSessionStore } from '@/stores/session.js'

import Aura from '@primeuix/themes/aura';
import PrimeVue from 'primevue/config';
import Tooltip from 'primevue/tooltip';
import Ripple from 'primevue/ripple';
import ToastService from 'primevue/toastservice';
import ConfirmationService from 'primevue/confirmationservice';

// Importar localización
import { esLocale } from '@/locale/es.js';

import { registerSW } from 'virtual:pwa-register'

const updateSW = registerSW({ onNeedRefresh: () => updateSW() })

// Crear app y configurar
const app = createApp(App)

// Crear Pinia primero
const pinia = createPinia()
app.use(pinia)

app.use(PrimeVue, {
    theme: {
        preset: Aura,
        options: {
            darkModeSelector: '.app-dark',
        }
    },
    ripple: true,
    locale: esLocale
});

app.use(ToastService)
app.use(ConfirmationService)
app.directive('ripple', Ripple)
app.directive('tooltip', Tooltip)
app.use(router)

// **VERSIÓN SIMPLIFICADA:** Inicialización más robusta
async function initializeApp() {
    console.log('🚀 Iniciando aplicación...');
    
    try {
        // Obtener stores
        const uiStore = useUIStore()
        const sessionStore = useSessionStore()
        
        console.log('📋 Configurando stores...');
        
        // Cargar configuración UI
        uiStore.loadUISetup()
        
        // **PASO 1:** Configurar listener PRIMERO (no bloquea)
        console.log('🎧 Configurando auth listener...');
        sessionStore.setupAuthListener()
        
        // **PASO 2:** Inicializar auth con timeout
        console.log('⏳ Inicializando autenticación...');
        
        const initPromise = sessionStore.initializeAuth()
        const timeoutPromise = new Promise((_, reject) => 
            setTimeout(() => reject(new Error('Timeout de inicialización')), 5000)
        )
        
        await Promise.race([initPromise, timeoutPromise])
        
        console.log('✅ Autenticación inicializada:', {
            isAuthenticated: sessionStore.isAuthenticated,
            userEmail: sessionStore.userEmail,
            initialized: sessionStore.initialized
        });
        
    } catch (error) {
        console.error('⚠️ Error/timeout en inicialización:', error.message);
        // Continuar de todas formas
    }
    
    // **PASO 3:** Montar app siempre (con o sin auth)
    console.log('🎯 Montando aplicación...');
    app.mount('#app')
    console.log('✅ Aplicación montada exitosamente');
}

// Inicializar la aplicación
initializeApp()
