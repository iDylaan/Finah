import '@/assets/styles.scss';

import { createApp } from 'vue'
import App from './App.vue'

import router from './router/index.js'

import { createPinia } from 'pinia'

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
app.use(createPinia())
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
app.mount('#app')
