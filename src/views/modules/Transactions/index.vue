<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabase.js'
import { useModalsStore } from '@/stores/ui-modals.js'
import { useAccountsStore } from '@/stores/accounts.js'
import { useCategoriesStore } from '@/stores/categories.js'

const modalsStore = useModalsStore()
const accountsStore = useAccountsStore()
const categoriesStore = useCategoriesStore()

const transactions = ref([])
const loading = ref(true)
const loadingMore = ref(false)
const hasMore = ref(true)
const PAGE_SIZE = 20

// Filters
const filterType = ref(null)
const filterAccount = ref(null)
const searchQuery = ref('')

const typeOptions = [
    { label: 'Todos', value: null },
    { label: 'Gastos', value: 'gasto' },
    { label: 'Ingresos', value: 'ingreso' },
    { label: 'Transferencias', value: 'transferencia' }
]

const accountOptions = computed(() => {
    return [
        { label: 'Todas', value: null },
        ...accountsStore.accounts
            .filter(a => !a.deleted_at)
            .map(a => ({ label: a.nombre, value: a.id }))
    ]
})

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

    const diffDays = Math.floor((today - date) / (1000 * 60 * 60 * 24))
    if (diffDays < 7) return date.toLocaleDateString('es-MX', { weekday: 'long' })

    return date.toLocaleDateString('es-MX', { day: 'numeric', month: 'long', year: 'numeric' })
}

const getTransactionColor = (tipo) => {
    if (tipo === 'ingreso') return 'text-green-600 dark:text-green-400'
    if (tipo === 'gasto') return 'text-red-500 dark:text-red-400'
    return 'text-blue-500 dark:text-blue-400'
}

const getTransactionSign = (tipo) => {
    return tipo === 'ingreso' ? '+' : '-'
}

const getCategoryIcon = (t) => {
    return t.categorias?.nombre_icono || t.categorias?.grupos_categoria?.nombre_icono || 'receipt_long'
}

const getCategoryColor = (t) => {
    return t.categorias?.grupos_categoria?.color || 'var(--p-primary-color)'
}

const groupedTransactions = computed(() => {
    const groups = {}
    for (const t of transactions.value) {
        const key = t.fecha_ocurrencia
        if (!groups[key]) groups[key] = []
        groups[key].push(t)
    }
    return Object.entries(groups)
        .sort(([a], [b]) => b.localeCompare(a))
        .map(([date, items]) => ({
            date,
            label: formatDate(date),
            items
        }))
})

const buildQuery = () => {
    let query = supabase
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
        .is('deleted_at', null)
        .order('fecha_ocurrencia', { ascending: false })

    if (filterType.value) {
        query = query.eq('tipo', filterType.value)
    }
    if (filterAccount.value) {
        query = query.eq('cuenta_id', filterAccount.value)
    }
    if (searchQuery.value.trim()) {
        query = query.ilike('descripcion', `%${searchQuery.value.trim()}%`)
    }

    return query
}

const fetchTransactions = async (append = false) => {
    if (!append) {
        loading.value = true
        transactions.value = []
    } else {
        loadingMore.value = true
    }

    try {
        const { data: { user } } = await supabase.auth.getUser()
        if (!user) return

        const offset = append ? transactions.value.length : 0
        const query = buildQuery()
            .eq('usuario_id', user.id)
            .range(offset, offset + PAGE_SIZE - 1)

        const { data, error } = await query
        if (error) throw error

        if (append) {
            transactions.value.push(...(data || []))
        } else {
            transactions.value = data || []
        }

        hasMore.value = (data || []).length === PAGE_SIZE
    } catch (err) {
        console.error('Error cargando transacciones:', err)
    } finally {
        loading.value = false
        loadingMore.value = false
    }
}

// Infinite scroll observer
const sentinelRef = ref(null)
let observer = null

onMounted(async () => {
    await accountsStore.fetchAccountsWithDetails()
    await fetchTransactions()

    observer = new IntersectionObserver(
        (entries) => {
            if (entries[0].isIntersecting && hasMore.value && !loadingMore.value) {
                fetchTransactions(true)
            }
        },
        { rootMargin: '200px' }
    )
    if (sentinelRef.value) {
        observer.observe(sentinelRef.value)
    }
})

onUnmounted(() => {
    if (observer) observer.disconnect()
})

// Re-fetch on filter change
const applyFilters = () => {
    fetchTransactions()
}

let searchTimeout = null
const onSearch = () => {
    clearTimeout(searchTimeout)
    searchTimeout = setTimeout(() => fetchTransactions(), 400)
}
</script>

<template>
    <div>
        <!-- Header -->
        <div class="flex items-center justify-between mb-4">
            <h1 class="text-2xl font-bold text-surface-900 dark:text-surface-0">Transacciones</h1>
        </div>

        <!-- Filters -->
        <div class="flex flex-col md:flex-row gap-2 mb-4">
            <div class="flex-1">
                <IconField>
                    <InputIcon class="pi pi-search" />
                    <InputText
                        v-model="searchQuery"
                        placeholder="Buscar por descripción..."
                        class="w-full"
                        @input="onSearch"
                    />
                </IconField>
            </div>
            <div class="flex gap-2">
                <Select
                    v-model="filterType"
                    :options="typeOptions"
                    optionLabel="label"
                    optionValue="value"
                    placeholder="Tipo"
                    class="w-36"
                    @change="applyFilters"
                />
                <Select
                    v-model="filterAccount"
                    :options="accountOptions"
                    optionLabel="label"
                    optionValue="value"
                    placeholder="Cuenta"
                    class="w-36"
                    @change="applyFilters"
                />
            </div>
        </div>

        <!-- Loading -->
        <div v-if="loading" class="flex items-center justify-center py-16">
            <i class="pi pi-spin pi-spinner text-3xl text-surface-400"></i>
        </div>

        <!-- Empty state -->
        <div v-else-if="transactions.length === 0" class="text-center py-16 text-surface-400">
            <span class="material-symbols-outlined text-6xl mb-3 block">receipt_long</span>
            <p class="text-lg font-medium mb-1">Sin transacciones</p>
            <p class="text-sm">Registra tu primer movimiento con el botón +</p>
        </div>

        <!-- Transaction feed -->
        <div v-else class="space-y-5">
            <div v-for="group in groupedTransactions" :key="group.date">
                <p class="text-xs font-semibold text-surface-400 uppercase tracking-wider mb-2 px-1">
                    {{ group.label }}
                </p>
                <div class="space-y-0.5">
                    <div
                        v-for="t in group.items"
                        :key="t.id"
                        class="flex items-center gap-3 py-3 px-2 rounded-xl hover:bg-surface-50 dark:hover:bg-surface-700/50 transition-colors cursor-pointer"
                    >
                        <div
                            class="w-11 h-11 rounded-xl flex items-center justify-center shrink-0"
                            :style="{ backgroundColor: getCategoryColor(t) + '20' }"
                        >
                            <span
                                class="material-symbols-outlined text-xl"
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
                        <span class="text-sm font-bold whitespace-nowrap" :class="getTransactionColor(t.tipo)">
                            {{ getTransactionSign(t.tipo) }}{{ formatCurrency(t.monto) }}
                        </span>
                    </div>
                </div>
            </div>

            <!-- Infinite scroll sentinel -->
            <div ref="sentinelRef" class="h-1"></div>

            <!-- Loading more -->
            <div v-if="loadingMore" class="flex items-center justify-center py-4">
                <i class="pi pi-spin pi-spinner text-lg text-surface-400"></i>
            </div>

            <!-- End of list -->
            <div v-if="!hasMore && transactions.length > 0" class="text-center py-4 text-surface-400 text-xs">
                No hay más transacciones
            </div>
        </div>
    </div>
</template>
