<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase.js'

const ingresos = ref(0)
const gastos = ref(0)
const loading = ref(true)

const formatCurrency = (val) => {
    return new Intl.NumberFormat('es-MX', {
        style: 'currency',
        currency: 'MXN',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0
    }).format(val)
}

const porcentajeGasto = () => {
    if (ingresos.value === 0) return 0
    return Math.min(100, Math.round((gastos.value / ingresos.value) * 100))
}

onMounted(async () => {
    try {
        const { data: { user } } = await supabase.auth.getUser()
        if (!user) return

        const now = new Date()
        const firstDay = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().split('T')[0]
        const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0).toISOString().split('T')[0]

        const { data, error } = await supabase
            .from('transacciones')
            .select('tipo, monto')
            .eq('usuario_id', user.id)
            .is('deleted_at', null)
            .gte('fecha_ocurrencia', firstDay)
            .lte('fecha_ocurrencia', lastDay)

        if (error) throw error

        for (const t of (data || [])) {
            const monto = parseFloat(t.monto)
            if (t.tipo === 'ingreso') {
                ingresos.value += monto
            } else if (t.tipo === 'gasto' || t.tipo === 'transferencia') {
                gastos.value += monto
            }
        }
    } catch (err) {
        console.error('Error cargando resumen mensual:', err)
    } finally {
        loading.value = false
    }
})
</script>

<template>
    <div class="rounded-2xl p-5 bg-surface-0 dark:bg-surface-800 border border-surface-200 dark:border-surface-700">
        <h3 class="text-base font-semibold text-surface-900 dark:text-surface-0 mb-4">Resumen del mes</h3>

        <div v-if="loading" class="flex items-center justify-center py-4">
            <i class="pi pi-spin pi-spinner text-xl text-surface-400"></i>
        </div>

        <template v-else>
            <div class="flex justify-between items-end mb-3">
                <div>
                    <p class="text-xs text-surface-500 dark:text-surface-400 mb-0.5">Ingresos</p>
                    <p class="text-lg font-bold text-green-600 dark:text-green-400">{{ formatCurrency(ingresos) }}</p>
                </div>
                <div class="text-right">
                    <p class="text-xs text-surface-500 dark:text-surface-400 mb-0.5">Gastos</p>
                    <p class="text-lg font-bold text-red-500 dark:text-red-400">{{ formatCurrency(gastos) }}</p>
                </div>
            </div>

            <!-- Progress bar -->
            <div class="w-full h-2 rounded-full bg-surface-200 dark:bg-surface-600 overflow-hidden">
                <div
                    class="h-full rounded-full transition-all duration-500"
                    :class="{
                        'bg-green-500': porcentajeGasto() < 50,
                        'bg-yellow-500': porcentajeGasto() >= 50 && porcentajeGasto() < 80,
                        'bg-orange-500': porcentajeGasto() >= 80 && porcentajeGasto() < 100,
                        'bg-red-500': porcentajeGasto() >= 100
                    }"
                    :style="{ width: porcentajeGasto() + '%' }"
                ></div>
            </div>
            <p class="text-xs text-surface-400 mt-1.5">
                {{ porcentajeGasto() }}% de tus ingresos gastado
            </p>
        </template>
    </div>
</template>
