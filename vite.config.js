import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import vueJsx from '@vitejs/plugin-vue-jsx';
import vueDevTools from 'vite-plugin-vue-devtools';
import Components from 'unplugin-vue-components/vite';
import { PrimeVueResolver } from '@primevue/auto-import-resolver';
import { VitePWA } from 'vite-plugin-pwa';
import { resolve } from 'path';

export default defineConfig({
  optimizeDeps: {
    noDiscovery: true
  },
  plugins: [
    vue(),
    vueJsx(),
    vueDevTools(),
    Components({
      resolvers: [
        PrimeVueResolver()
      ]
    }),
    VitePWA({
      registerType: 'autoUpdate',
      manifest: {
        name: 'Finheal',
        short_name: 'Finheal',
        start_url: '/',
        display: 'standalone',
        background_color: '#ffffff',
        icons: [
          // { src: '/pwa-192x192.png', sizes: '192x192', type: 'image/png' },
          // { src: '/pwa-512x512.png', sizes: '512x512', type: 'image/png' }
        ]
      }
    }),
  ],
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src')
    }
  },
  base: './',
  build: {
    outDir: 'dist'
  }
})
