<template>
    <PageLayout 
        title="Divisor de Gastos" 
        description="Divide gastos proporcionalmente según los ingresos de cada persona"
    >
        <!-- Acciones del header -->
        <template #actions>
            <Button 
                icon="pi pi-refresh" 
                @click="divisorStore.limpiarDatos" 
                severity="secondary" 
                outlined 
                size="small"
                v-tooltip.bottom="'Limpiar datos'"
            />
        </template>

        <div class="space-y-4 md:space-y-6">
            <!-- Ingresos de las personas -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-3 md:gap-4">
                <!-- Persona 1 -->
                <div class="bg-surface-0 dark:bg-surface-800 rounded-xl border border-surface-200 dark:border-surface-700 overflow-hidden">
                    <div class="bg-gradient-to-r from-blue-500 to-blue-600 p-3 md:p-4">
                        <div class="flex items-center gap-2">
                            <div class="w-8 h-8 md:w-10 md:h-10 rounded-lg bg-white/20 flex items-center justify-center">
                                <i class="pi pi-user text-white text-sm md:text-base"></i>
                            </div>
                            <h3 class="text-base md:text-lg font-semibold text-white">
                                Persona 1
                            </h3>
                        </div>
                    </div>

                    <div class="p-3 md:p-4 space-y-3 md:space-y-4">
                        <div class="field">
                            <label class="block text-xs md:text-sm font-medium mb-2 text-surface-700 dark:text-surface-300">
                                Periodo de ingresos
                            </label>
                            <Select 
                                v-model="divisorStore.persona1.periodo"
                                :options="periodoOptions"
                                optionLabel="label"
                                optionValue="value"
                                placeholder="Seleccionar periodo"
                                class="w-full"
                            />
                        </div>

                        <div class="field">
                            <label class="block text-xs md:text-sm font-medium mb-2 text-surface-700 dark:text-surface-300">
                                Ingresos ({{ divisorStore.persona1.periodo }})
                            </label>
                            <InputNumber 
                                v-model="divisorStore.persona1.ingresos"
                                mode="currency"
                                currency="MXN"
                                locale="es-MX"
                                :min="0"
                                :minFractionDigits="2"
                                class="w-full"
                                placeholder="$0.00"
                            />
                        </div>

                        <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-3 border border-blue-200 dark:border-blue-800">
                            <p class="text-xs text-blue-800 dark:text-blue-200 font-medium">
                                💰 Ingreso mensual equivalente
                            </p>
                            <p class="text-lg md:text-xl font-bold text-blue-600 dark:text-blue-400 mt-1">
                                {{ formatCurrency(divisorStore.ingresosMensualesPersona1) }}
                            </p>
                        </div>
                    </div>
                </div>

                <!-- Persona 2 -->
                <div class="bg-surface-0 dark:bg-surface-800 rounded-xl border border-surface-200 dark:border-surface-700 overflow-hidden">
                    <div class="bg-gradient-to-r from-purple-500 to-purple-600 p-3 md:p-4">
                        <div class="flex items-center gap-2">
                            <div class="w-8 h-8 md:w-10 md:h-10 rounded-lg bg-white/20 flex items-center justify-center">
                                <i class="pi pi-user text-white text-sm md:text-base"></i>
                            </div>
                            <h3 class="text-base md:text-lg font-semibold text-white">
                                Persona 2
                            </h3>
                        </div>
                    </div>

                    <div class="p-3 md:p-4 space-y-3 md:space-y-4">
                        <div class="field">
                            <label class="block text-xs md:text-sm font-medium mb-2 text-surface-700 dark:text-surface-300">
                                Periodo de ingresos
                            </label>
                            <Select 
                                v-model="divisorStore.persona2.periodo"
                                :options="periodoOptions"
                                optionLabel="label"
                                optionValue="value"
                                placeholder="Seleccionar periodo"
                                class="w-full"
                            />
                        </div>

                        <div class="field">
                            <label class="block text-xs md:text-sm font-medium mb-2 text-surface-700 dark:text-surface-300">
                                Ingresos ({{ divisorStore.persona2.periodo }})
                            </label>
                            <InputNumber 
                                v-model="divisorStore.persona2.ingresos"
                                mode="currency"
                                currency="MXN"
                                locale="es-MX"
                                :min="0"
                                :minFractionDigits="2"
                                class="w-full"
                                placeholder="$0.00"
                            />
                        </div>

                        <div class="bg-purple-50 dark:bg-purple-900/20 rounded-lg p-3 border border-purple-200 dark:border-purple-800">
                            <p class="text-xs text-purple-800 dark:text-purple-200 font-medium">
                                💰 Ingreso mensual equivalente
                            </p>
                            <p class="text-lg md:text-xl font-bold text-purple-600 dark:text-purple-400 mt-1">
                                {{ formatCurrency(divisorStore.ingresosMensualesPersona2) }}
                            </p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Costo Total -->
            <div class="bg-surface-0 dark:bg-surface-800 p-4 md:p-6 rounded-xl border border-surface-200 dark:border-surface-700">
                <div class="flex items-center gap-2 mb-3 md:mb-4">
                    <div class="w-10 h-10 rounded-lg bg-orange-100 dark:bg-orange-900/30 flex items-center justify-center">
                        <i class="pi pi-calculator text-orange-600 dark:text-orange-400 text-lg"></i>
                    </div>
                    <h3 class="text-base md:text-lg font-semibold text-surface-900 dark:text-surface-0">
                        Costo Total a Dividir
                    </h3>
                </div>
                
                <div class="field">
                    <label class="block text-xs md:text-sm font-medium mb-2 text-surface-700 dark:text-surface-300">
                        Monto total del gasto
                    </label>
                    <InputNumber 
                        v-model="divisorStore.costoTotal"
                        mode="currency"
                        currency="MXN"
                        locale="es-MX"
                        :min="0"
                        :minFractionDigits="2"
                        class="w-full"
                        placeholder="$0.00"
                    />
                </div>
            </div>

            <!-- Resultados -->
            <div v-if="divisorStore.totalIngresosMensuales > 0 && divisorStore.costoTotal > 0"
                class="bg-gradient-to-br from-green-50 to-emerald-50 dark:from-green-900/20 dark:to-emerald-900/20 rounded-xl border border-green-200 dark:border-green-800 overflow-hidden">
                
                <div class="bg-green-600 dark:bg-green-700 p-3 md:p-4">
                    <div class="flex items-center gap-2">
                        <i class="pi pi-check-circle text-white text-lg md:text-xl"></i>
                        <h3 class="text-base md:text-lg font-semibold text-white">
                            División Proporcional
                        </h3>
                    </div>
                </div>

                <div class="p-4 md:p-6">
                    <!-- Cards de resultados -->
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-3 md:gap-4 mb-4 md:mb-6">
                        <!-- Resultado Persona 1 -->
                        <div class="bg-white dark:bg-surface-800 rounded-lg p-4 border border-green-200 dark:border-green-800 shadow-sm">
                            <div class="flex items-center gap-2 mb-3">
                                <div class="w-8 h-8 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
                                    <i class="pi pi-user text-blue-600 dark:text-blue-400 text-sm"></i>
                                </div>
                                <h4 class="font-semibold text-surface-900 dark:text-surface-0">
                                    Persona 1
                                </h4>
                            </div>
                            
                            <div class="space-y-2">
                                <div class="flex justify-between items-center">
                                    <span class="text-xs md:text-sm text-surface-600 dark:text-surface-400">
                                        Porcentaje
                                    </span>
                                    <span class="text-sm md:text-base font-semibold text-blue-600 dark:text-blue-400">
                                        {{ formatPercentage(divisorStore.porcentajePersona1) }}%
                                    </span>
                                </div>
                                <div class="pt-2 border-t border-surface-200 dark:border-surface-700">
                                    <p class="text-xs text-surface-500 dark:text-surface-400 mb-1">
                                        Debe pagar
                                    </p>
                                    <p class="text-xl md:text-2xl font-bold text-green-600 dark:text-green-400">
                                        {{ formatCurrency(divisorStore.montoPersona1) }}
                                    </p>
                                </div>
                            </div>
                        </div>

                        <!-- Resultado Persona 2 -->
                        <div class="bg-white dark:bg-surface-800 rounded-lg p-4 border border-green-200 dark:border-green-800 shadow-sm">
                            <div class="flex items-center gap-2 mb-3">
                                <div class="w-8 h-8 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center">
                                    <i class="pi pi-user text-purple-600 dark:text-purple-400 text-sm"></i>
                                </div>
                                <h4 class="font-semibold text-surface-900 dark:text-surface-0">
                                    Persona 2
                                </h4>
                            </div>
                            
                            <div class="space-y-2">
                                <div class="flex justify-between items-center">
                                    <span class="text-xs md:text-sm text-surface-600 dark:text-surface-400">
                                        Porcentaje
                                    </span>
                                    <span class="text-sm md:text-base font-semibold text-purple-600 dark:text-purple-400">
                                        {{ formatPercentage(divisorStore.porcentajePersona2) }}%
                                    </span>
                                </div>
                                <div class="pt-2 border-t border-surface-200 dark:border-surface-700">
                                    <p class="text-xs text-surface-500 dark:text-surface-400 mb-1">
                                        Debe pagar
                                    </p>
                                    <p class="text-xl md:text-2xl font-bold text-green-600 dark:text-green-400">
                                        {{ formatCurrency(divisorStore.montoPersona2) }}
                                    </p>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Resumen -->
                    <div class="bg-white/50 dark:bg-surface-900/50 rounded-lg p-3 md:p-4 border border-green-200 dark:border-green-800">
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-2 md:gap-4 text-xs md:text-sm">
                            <div class="flex justify-between md:justify-start md:gap-2">
                                <span class="text-surface-600 dark:text-surface-400">Total de ingresos mensuales:</span>
                                <span class="font-semibold text-surface-900 dark:text-surface-0">
                                    {{ formatCurrency(divisorStore.totalIngresosMensuales) }}
                                </span>
                            </div>
                            <div class="flex justify-between md:justify-start md:gap-2">
                                <span class="text-surface-600 dark:text-surface-400">Verificación:</span>
                                <span class="font-semibold text-green-600 dark:text-green-400">
                                    {{ formatCurrency(divisorStore.montoPersona1 + divisorStore.montoPersona2) }} = 
                                    {{ formatCurrency(divisorStore.costoTotal) }}
                                    <i class="pi pi-check-circle ml-1"></i>
                                </span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Estado vacío -->
            <div v-else class="text-center py-8 md:py-12">
                <div class="w-16 h-16 md:w-20 md:h-20 mx-auto mb-4 rounded-full bg-surface-100 dark:bg-surface-800 flex items-center justify-center">
                    <i class="pi pi-calculator text-surface-400 dark:text-surface-500 text-2xl md:text-3xl"></i>
                </div>
                <h3 class="text-base md:text-lg font-medium text-surface-700 dark:text-surface-300 mb-2">
                    Ingresa los datos para calcular
                </h3>
                <p class="text-xs md:text-sm text-surface-500 dark:text-surface-400">
                    Completa los ingresos de ambas personas y el costo total para ver la división
                </p>
            </div>
        </div>
    </PageLayout>
</template>

<script setup>
// IMPORTS
import { onMounted } from 'vue'
import { useDivisorGastosStore } from '@/stores/divisor_gastos'
import { useUIStore } from '@/stores/ui'
import PageLayout from '@/components/PageLayout.vue'

// STORES
const divisorStore = useDivisorGastosStore()
const uiStore = useUIStore();

// STATES
const periodoOptions = [
    { label: 'Mensual', value: 'mensual' },
    { label: 'Quincenal', value: 'quincenal' }
]

// FUNCTIONS
const formatCurrency = (amount) => {
    return new Intl.NumberFormat('es-MX', {
        style: 'currency',
        currency: 'MXN'
    }).format(amount || 0)
}

const formatPercentage = (percentage) => {
    return new Intl.NumberFormat('es-MX', {
        minimumFractionDigits: 1,
        maximumFractionDigits: 1
    }).format(percentage || 0)
}

// HOOKS
onMounted(() => {
    uiStore.setTitlePage('Divisor de Gastos');
});
</script>

<style lang="scss" scoped></style>