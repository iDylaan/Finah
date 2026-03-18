<script setup>
import { useRouter } from 'vue-router'
import { useUIStore } from '@/stores/ui.js'

const router = useRouter()
const uiStore = useUIStore()

const menuItems = [
    { label: 'Perfil', icon: 'person', route: '/profile', color: 'bg-blue-500' },
    { label: 'Grupos', icon: 'group', route: '/groups', color: 'bg-violet-500' },
    { label: 'Gráficas', icon: 'bar_chart', route: '/charts', color: 'bg-emerald-500' },
    { label: 'Categorías', icon: 'category', route: '/categories', color: 'bg-amber-500' },
    { label: 'Niveles', icon: 'backlight_low', route: '/levels', color: 'bg-rose-500' },
    { label: 'Bancos', icon: 'account_balance', route: '/banks', color: 'bg-cyan-500' },
    { label: 'Divisor', icon: 'money_off', route: '/divisor_de_gastos', color: 'bg-orange-500' },
]

const navigate = (route) => {
    router.push(route)
}
</script>

<template>
    <div class="px-4 py-6">
        <h2 class="text-2xl font-bold text-surface-900 dark:text-surface-0 mb-6">Más opciones</h2>
        <div class="grid grid-cols-3 gap-4">
            <button
                v-for="item in menuItems"
                :key="item.route"
                class="flex flex-col items-center gap-2 p-4 rounded-2xl bg-surface-50 dark:bg-surface-800 hover:bg-surface-100 dark:hover:bg-surface-700 transition-colors cursor-pointer border-none"
                @click="navigate(item.route)"
            >
                <div
                    class="w-12 h-12 rounded-xl flex items-center justify-center"
                    :class="item.color"
                >
                    <span class="material-symbols-outlined text-white text-2xl">{{ item.icon }}</span>
                </div>
                <span class="text-xs font-semibold text-surface-700 dark:text-surface-200 text-center leading-tight">
                    {{ item.label }}
                </span>
            </button>
        </div>

        <!-- App info -->
        <div class="mt-8 text-center text-surface-400 dark:text-surface-500 text-xs">
            <p>Finah v1.0</p>
            <button
                class="mt-2 text-primary underline cursor-pointer bg-transparent border-none text-xs"
                @click="uiStore.executeDarkModeToggle"
            >
                <i :class="['pi', uiStore.isDarkTheme ? 'pi-sun' : 'pi-moon']" class="mr-1"></i>
                {{ uiStore.isDarkTheme ? 'Modo claro' : 'Modo oscuro' }}
            </button>
        </div>
    </div>
</template>
