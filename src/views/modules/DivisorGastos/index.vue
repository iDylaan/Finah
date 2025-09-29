<template>
    <div class="p-6 max-w-4xl mx-auto">
        <div class="mb-6">
            <h1 class="text-3xl font-bold text-surface-900 dark:text-surface-0 mb-2">
                Divisor de Gastos
            </h1>
            <p class="text-surface-600 dark:text-surface-400">
                Divide gastos entre diferentes categorías y grupos de usuarios.
            </p>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
            <!-- Persona 1 -->
            <div class="bg-surface-0 dark:bg-surface-800 p-6 rounded-lg border">
                <h3 class="text-xl font-semibold mb-4 text-surface-900 dark:text-surface-0">
                    Persona 1
                </h3>

                <div class="space-y-4">
                    <div>
                        <label class="block text-sm font-medium mb-2 text-surface-700 dark:text-surface-300">
                            Periodo de ingresos
                        </label>
                        <select v-model="divisorStore.persona1.periodo"
                            class="w-full px-3 py-2 border border-surface-300 dark:border-surface-600 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500 bg-surface-0 dark:bg-surface-700 text-surface-900 dark:text-surface-0">
                            <option value="mensual">Mensual</option>
                            <option value="quincenal">Quincenal</option>
                        </select>
                    </div>

                    <div>
                        <label class="block text-sm font-medium mb-2 text-surface-700 dark:text-surface-300">
                            Ingresos ({{ divisorStore.persona1.periodo }})
                        </label>
                        <input v-model.number="divisorStore.persona1.ingresos" type="number" step="0.01" min="0"
                            class="w-full px-3 py-2 border border-surface-300 dark:border-surface-600 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500 bg-surface-0 dark:bg-surface-700 text-surface-900 dark:text-surface-0"
                            placeholder="0.00" />
                    </div>

                    <div class="text-sm text-surface-600 dark:text-surface-400">
                        <p>Ingreso mensual equivalente: ${{ formatCurrency(divisorStore.ingresosMensualesPersona1) }}
                        </p>
                    </div>
                </div>
            </div>

            <!-- Persona 2 -->
            <div class="bg-surface-0 dark:bg-surface-800 p-6 rounded-lg border">
                <h3 class="text-xl font-semibold mb-4 text-surface-900 dark:text-surface-0">
                    Persona 2
                </h3>

                <div class="space-y-4">
                    <div>
                        <label class="block text-sm font-medium mb-2 text-surface-700 dark:text-surface-300">
                            Periodo de ingresos
                        </label>
                        <select v-model="divisorStore.persona2.periodo"
                            class="w-full px-3 py-2 border border-surface-300 dark:border-surface-600 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500 bg-surface-0 dark:bg-surface-700 text-surface-900 dark:text-surface-0">
                            <option value="mensual">Mensual</option>
                            <option value="quincenal">Quincenal</option>
                        </select>
                    </div>

                    <div>
                        <label class="block text-sm font-medium mb-2 text-surface-700 dark:text-surface-300">
                            Ingresos ({{ divisorStore.persona2.periodo }})
                        </label>
                        <input v-model.number="divisorStore.persona2.ingresos" type="number" step="0.01" min="0"
                            class="w-full px-3 py-2 border border-surface-300 dark:border-surface-600 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500 bg-surface-0 dark:bg-surface-700 text-surface-900 dark:text-surface-0"
                            placeholder="0.00" />
                    </div>

                    <div class="text-sm text-surface-600 dark:text-surface-400">
                        <p>Ingreso mensual equivalente: ${{ formatCurrency(divisorStore.ingresosMensualesPersona2) }}
                        </p>
                    </div>
                </div>
            </div>
        </div>

        <!-- Costo Total -->
        <div class="bg-surface-0 dark:bg-surface-800 p-6 rounded-lg border mb-6">
            <h3 class="text-xl font-semibold mb-4 text-surface-900 dark:text-surface-0">
                Costo Total a Dividir
            </h3>
            <div>
                <label class="block text-sm font-medium mb-2 text-surface-700 dark:text-surface-300">
                    Monto total
                </label>
                <input v-model.number="divisorStore.costoTotal" type="number" step="0.01" min="0"
                    class="w-full px-3 py-2 border border-surface-300 dark:border-surface-600 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500 bg-surface-0 dark:bg-surface-700 text-surface-900 dark:text-surface-0"
                    placeholder="0.00" />
            </div>
        </div>

        <!-- Resultados -->
        <div v-if="divisorStore.totalIngresosMensuales > 0 && divisorStore.costoTotal > 0"
            class="bg-green-50 dark:bg-green-900/20 p-6 rounded-lg border border-green-200 dark:border-green-800">
            <h3 class="text-xl font-semibold mb-4 text-green-800 dark:text-green-200">
                División Proporcional
            </h3>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div class="bg-white dark:bg-surface-800 p-4 rounded-lg">
                    <h4 class="font-semibold text-surface-900 dark:text-surface-0 mb-2">
                        Persona 1
                    </h4>
                    <div class="space-y-1 text-sm">
                        <p class="text-surface-600 dark:text-surface-400">
                            Porcentaje: {{ formatPercentage(divisorStore.porcentajePersona1) }}%
                        </p>
                        <p class="text-lg font-bold text-green-600 dark:text-green-400">
                            Debe pagar: ${{ formatCurrency(divisorStore.montoPersona1) }}
                        </p>
                    </div>
                </div>

                <div class="bg-white dark:bg-surface-800 p-4 rounded-lg">
                    <h4 class="font-semibold text-surface-900 dark:text-surface-0 mb-2">
                        Persona 2
                    </h4>
                    <div class="space-y-1 text-sm">
                        <p class="text-surface-600 dark:text-surface-400">
                            Porcentaje: {{ formatPercentage(divisorStore.porcentajePersona2) }}%
                        </p>
                        <p class="text-lg font-bold text-green-600 dark:text-green-400">
                            Debe pagar: ${{ formatCurrency(divisorStore.montoPersona2) }}
                        </p>
                    </div>
                </div>
            </div>

            <div class="mt-4 pt-4 border-t border-green-200 dark:border-green-800">
                <p class="text-center text-surface-600 dark:text-surface-400">
                    Total de ingresos mensuales: ${{ formatCurrency(divisorStore.totalIngresosMensuales) }}
                </p>
                <p class="text-center text-surface-600 dark:text-surface-400">
                    Verificación: ${{ formatCurrency(divisorStore.montoPersona1 + divisorStore.montoPersona2) }} = ${{
                        formatCurrency(divisorStore.costoTotal) }}
                </p>
            </div>
        </div>

        <!-- Botón limpiar -->
        <div class="mt-6 text-center">
            <button @click="divisorStore.limpiarDatos"
                class="px-4 py-2 bg-surface-500 hover:bg-surface-600 text-white rounded-md transition-colors">
                Limpiar Datos
            </button>
        </div>
    </div>
</template>

<script setup>
import { useDivisorGastosStore } from '@/stores/divisor_gastos'

const divisorStore = useDivisorGastosStore()

const formatCurrency = (amount) => {
    return new Intl.NumberFormat('es-MX', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
    }).format(amount || 0)
}

const formatPercentage = (percentage) => {
    return new Intl.NumberFormat('es-MX', {
        minimumFractionDigits: 1,
        maximumFractionDigits: 1
    }).format(percentage || 0)
}
</script>

<style lang="scss" scoped></style>