import '@/assets/styles.scss';

import { createApp, nextTick } from 'vue'
import App from './App.vue'

import router from './router/index.js'

import { createPinia } from 'pinia'
import { useUIStore } from '@/stores/ui.js'

import Aura from '@primeuix/themes/aura';
import PrimeVue from 'primevue/config';
import Tooltip from 'primevue/tooltip';
import Ripple from 'primevue/ripple';
import ConfirmationService from 'primevue/confirmationservice';
import ToastService from 'primevue/toastservice';

import '@/assets/styles.scss';

import { registerSW } from 'virtual:pwa-register'

const updateSW = registerSW({ onNeedRefresh: () => updateSW() })

const app = createApp(App)

// Crear Pinia primero
const pinia = createPinia()
app.use(pinia)

app.use(router)
app.use(PrimeVue, {
    theme: {
        preset: Aura,
        options: {
            darkModeSelector: '.app-dark',
        },
        locale: 'es',
    },
    ripple: true
});
app.use(ToastService)
app.directive('ripple', Ripple)
app.directive('tooltip', Tooltip)
app.use(ConfirmationService);

// Montar la aplicación
app.mount('#app')

// Inicializar la UI store después de montar la aplicación
nextTick(() => {
    const uiStore = useUIStore()
    uiStore.loadUISetup()
})
