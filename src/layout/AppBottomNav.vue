<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useModalsStore } from '@/stores/ui-modals.js'

const route = useRoute()
const router = useRouter()
const modalsStore = useModalsStore()

const tabs = [
    { label: 'Inicio', icon: 'home', route: '/' },
    { label: 'Cuentas', icon: 'account_balance_wallet', route: '/accounts' },
    { label: 'Nuevo', icon: 'add', route: null, isFab: true },
    { label: 'Movimientos', icon: 'receipt_long', route: '/transactions' },
    { label: 'Más', icon: 'menu', route: '/more' }
]

const activeTab = computed(() => {
    const path = route.path
    if (path === '/') return '/'
    if (path.startsWith('/accounts')) return '/accounts'
    if (path.startsWith('/transactions')) return '/transactions'
    if (path === '/more' || ['/categories', '/levels', '/banks', '/groups', '/charts', '/divisor_de_gastos', '/profile'].some(p => path.startsWith(p))) return '/more'
    return path
})

const handleTabClick = (tab) => {
    if (tab.isFab) {
        modalsStore.openGastoModal()
        return
    }
    if (tab.route && tab.route !== route.path) {
        router.push(tab.route)
    }
}
</script>

<template>
    <nav class="bottom-nav">
        <button
            v-for="tab in tabs"
            :key="tab.label"
            class="bottom-nav-item"
            :class="{
                'bottom-nav-item--active': activeTab === tab.route,
                'bottom-nav-item--fab': tab.isFab
            }"
            @click="handleTabClick(tab)"
        >
            <div v-if="tab.isFab" class="bottom-nav-fab">
                <span class="material-symbols-outlined text-2xl text-white">{{ tab.icon }}</span>
            </div>
            <template v-else>
                <span class="material-symbols-outlined bottom-nav-icon">{{ tab.icon }}</span>
                <span class="bottom-nav-label">{{ tab.label }}</span>
            </template>
        </button>
    </nav>
</template>

<style scoped>
.bottom-nav {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    z-index: 1000;
    display: flex;
    align-items: flex-end;
    justify-content: space-around;
    height: 4rem;
    background: var(--p-surface-0);
    border-top: 1px solid var(--p-surface-200);
    padding-bottom: env(safe-area-inset-bottom, 0);
}

:root.app-dark .bottom-nav {
    background: var(--p-surface-900);
    border-top-color: var(--p-surface-700);
}

.bottom-nav-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    flex: 1;
    height: 100%;
    gap: 0.125rem;
    border: none;
    background: transparent;
    cursor: pointer;
    color: var(--p-surface-500);
    transition: color 0.2s ease;
    padding: 0.25rem 0;
    -webkit-tap-highlight-color: transparent;
}

.bottom-nav-item--active {
    color: var(--p-primary-color);
}

.bottom-nav-item--active .bottom-nav-icon {
    font-variation-settings: 'FILL' 1;
}

.bottom-nav-icon {
    font-size: 1.5rem;
    line-height: 1;
}

.bottom-nav-label {
    font-size: 0.625rem;
    font-weight: 600;
    letter-spacing: 0.02em;
}

.bottom-nav-item--fab {
    position: relative;
}

.bottom-nav-fab {
    width: 3.25rem;
    height: 3.25rem;
    border-radius: 1rem;
    display: flex;
    align-items: center;
    justify-content: center;
    background: var(--p-primary-color);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    transform: translateY(-0.5rem);
    transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.bottom-nav-fab:active {
    transform: translateY(-0.35rem);
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
}
</style>
