import '@/assets/styles.css';

import { createApp } from 'vue'
import { createPinia } from 'pinia'
import PrimeVue from 'primevue/config';
import Tooltip from 'primevue/tooltip';
import Ripple from 'primevue/ripple'
import ToastService from 'primevue/toastservice';
import Aura from '@primeuix/themes/aura';

import App from './App.vue'
import router from './router/index.js'

import { registerSW } from 'virtual:pwa-register'

const updateSW = registerSW({ onNeedRefresh: () => updateSW() })

const app = createApp(App)
app.use(createPinia())
app.use(router)
app.use(PrimeVue, {
    theme: {
        preset: Aura,
        options: {
            prefix: 'p',
            darkModeSelector: '.dark',
            cssLayer: 'app-styles, primevue'
        },
        theme: "light",
        locale: 'es',
    },
    ripple: true
});
app.use(ToastService)
app.directive('ripple', Ripple)
app.directive('tooltip', Tooltip)
app.mount('#app')
