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

// **VERSIÓN OPTIMIZADA:** Montar app inmediatamente y cargar datos en background
async function initializeApp() {
    console.log('🚀 Iniciando aplicación...');
    
    // Obtener stores
    const uiStore = useUIStore()
    const sessionStore = useSessionStore()
    
    // Cargar configuración UI (síncrono)
    uiStore.loadUISetup()
    
    // Inicializar detección de viewport móvil (síncrono)
    uiStore.initMobileDetection()
    
    // **MONTAR APP INMEDIATAMENTE**
    console.log('🎯 Montando aplicación...');
    app.mount('#app')
    console.log('✅ Aplicación montada');
    
    // Inicializar auth en background (no bloqueante)
    sessionStore.setupAuthListener()
    sessionStore.initializeAuth().catch(error => {
        console.error('⚠️ Error en inicialización de auth:', error.message);
    })
}

// Inicializar la aplicación
initializeApp()
