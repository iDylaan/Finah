import '@/assets/styles.scss';

import { createApp } from 'vue'
import App from './App.vue'

import router from './router/index.js'

import { createPinia } from 'pinia'
import { useUIStore } from '@/stores/ui.js'
import { useSessionStore } from '@/stores/session.js'

import Aura from '@primeuix/themes/aura';
import { definePreset } from '@primeuix/themes';
import PrimeVue from 'primevue/config';
import Tooltip from 'primevue/tooltip';
import Ripple from 'primevue/ripple';
import ToastService from 'primevue/toastservice';
import ConfirmationService from 'primevue/confirmationservice';

// Importar localización
import { esLocale } from '@/locale/es.js';

// Preset personalizado con colores Ocean Breeze (paleta del logo)
const FinahPreset = definePreset(Aura, {
    semantic: {
        primary: {
            50: '{sky.50}',
            100: '{sky.100}',
            200: '{sky.200}',
            300: '{sky.300}',
            400: '{sky.400}',
            500: '{sky.500}',
            600: '{sky.600}',
            700: '{sky.700}',
            800: '{sky.800}',
            900: '{sky.900}',
            950: '{sky.950}'
        },
        colorScheme: {
            light: {
                primary: {
                    color: '#00B4D8',
                    contrastColor: '#ffffff',
                    hoverColor: '#0096C7',
                    activeColor: '#0077B6'
                },
                highlight: {
                    background: '#00B4D8',
                    focusBackground: '#0096C7',
                    color: '#ffffff',
                    focusColor: '#ffffff'
                }
            },
            dark: {
                primary: {
                    color: '#48CAE4',
                    contrastColor: '#03045E',
                    hoverColor: '#90E0EF',
                    activeColor: '#ADE8F4'
                },
                highlight: {
                    background: '#00B4D8',
                    focusBackground: '#48CAE4',
                    color: '#03045E',
                    focusColor: '#03045E'
                }
            }
        }
    }
});

import { registerSW } from 'virtual:pwa-register'

const updateSW = registerSW({ onNeedRefresh: () => updateSW() })

// Crear app y configurar
const app = createApp(App)

// Crear Pinia primero
const pinia = createPinia()
app.use(pinia)

app.use(PrimeVue, {
    theme: {
        preset: FinahPreset,
        options: {
            darkModeSelector: '.app-dark',
            cssLayer: false
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
