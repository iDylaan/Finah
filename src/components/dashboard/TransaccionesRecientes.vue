<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase.js'

const router = useRouter()
const transactions = ref([])
const loading = ref(true)

const formatCurrency = (val) => {
    return new Intl.NumberFormat('es-MX', {
        style: 'currency',
        currency: 'MXN',
        minimumFractionDigits: 2
    }).format(val)
}

const formatDate = (dateStr) => {
    const date = new Date(dateStr + 'T00:00:00')
    const today = new Date()
    const yesterday = new Date()
    yesterday.setDate(today.getDate() - 1)

    if (date.toDateString() === today.toDateString()) return 'Hoy'
    if (date.toDateString() === yesterday.toDateString()) return 'Ayer'

    return date.toLocaleDateString('es-MX', { day: 'numeric', month: 'short' })
}

const getTransactionColor = (tipo) => {
    if (tipo === 'ingreso') return 'text-green-600 dark:text-green-400'
    if (tipo === 'gasto') return 'text-red-500 dark:text-red-400'
    return 'text-blue-500 dark:text-blue-400'
}

const getTransactionSign = (tipo) => {
    if (tipo === 'ingreso') return '+'
    return '-'
}

const getCategoryIcon = (t) => {
    return t.categorias?.nombre_icono || t.categorias?.grupos_categoria?.nombre_icono || 'receipt_long'
}

const getCategoryColor = (t) => {
    return t.categorias?.grupos_categoria?.color || 'var(--p-primary-color)'
}

// Group transactions by date
const groupedTransactions = () => {
    const groups = {}
    for (const t of transactions.value) {
        const key = t.fecha_ocurrencia
        if (!groups[key]) groups[key] = []
        groups[key].push(t)
    }
    return Object.entries(groups).map(([date, items]) => ({
        date,
        label: formatDate(date),
        items
    }))
}

onMounted(async () => {
    try {
        const { data: { user } } = await supabase.auth.getUser()
        if (!user) return

        const { data, error } = await supabase
            .from('transacciones')
            .select(`
                id, tipo, monto, fecha_ocurrencia, descripcion,
                categorias!transacciones_categoria_id_fkey (
                    nombre, nombre_icono, biblioteca_iconos,
                    grupos_categoria!categorias_grupo_id_fkey (
                        nombre, color, nombre_icono
                    )
                ),
                cuentas!transacciones_cuenta_id_fkey (
                    nombre
                )
            `)
            .eq('usuario_id', user.id)
            .is('deleted_at', null)
            .order('fecha_ocurrencia', { ascending: false })
            .limit(10)

        if (error) throw error
        transactions.value = data || []
    } catch (err) {
        console.error('Error cargando transacciones recientes:', err)
    } finally {
        loading.value = false
    }
})
</script>

<template>
    <div class="rounded-2xl p-5 bg-surface-0 dark:bg-surface-800 border border-surface-200 dark:border-surface-700">
        <div class="flex items-center justify-between mb-4">
            <h3 class="text-base font-semibold text-surface-900 dark:text-surface-0">Transacciones recientes</h3>
            <router-link
                to="/transactions"
                class="text-sm text-primary font-medium hover:underline no-underline"
            >
                Ver todas
            </router-link>
        </div>

        <div v-if="loading" class="flex items-center justify-center py-8">
            <i class="pi pi-spin pi-spinner text-xl text-surface-400"></i>
        </div>

        <div v-else-if="transactions.length === 0" class="text-center py-8 text-surface-400">
            <span class="material-symbols-outlined text-4xl mb-2 block">receipt_long</span>
            <p class="text-sm">Sin transacciones aún</p>
        </div>

        <div v-else class="space-y-4">
            <div v-for="group in groupedTransactions()" :key="group.date">
                <p class="text-xs font-medium text-surface-400 uppercase tracking-wide mb-2">{{ group.label }}</p>
                <div class="space-y-1">
                    <div
                        v-for="t in group.items"
                        :key="t.id"
                        class="flex items-center gap-3 py-2.5 px-1 rounded-xl hover:bg-surface-50 dark:hover:bg-surface-700/50 transition-colors cursor-pointer"
                    >
                        <div
                            class="w-10 h-10 rounded-xl flex items-center justify-center shrink-0"
                            :style="{ backgroundColor: getCategoryColor(t) + '20' }"
                        >
                            <span
                                class="material-symbols-outlined text-lg"
                                :style="{ color: getCategoryColor(t) }"
                            >{{ getCategoryIcon(t) }}</span>
                        </div>
                        <div class="flex-1 min-w-0">
                            <p class="text-sm font-medium text-surface-900 dark:text-surface-0 truncate">
                                {{ t.descripcion || t.categorias?.nombre || 'Transacción' }}
                            </p>
                            <p class="text-xs text-surface-400 truncate">
                                {{ t.cuentas?.nombre }}
                            </p>
                        </div>
                        <span class="text-sm font-semibold whitespace-nowrap" :class="getTransactionColor(t.tipo)">
                            {{ getTransactionSign(t.tipo) }}{{ formatCurrency(t.monto) }}
                        </span>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>
