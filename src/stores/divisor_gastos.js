import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useDivisorGastosStore = defineStore('divisorGastos', () => {
    // Estado
    const persona1 = ref({
        ingresos: 0,
        periodo: 'mensual' // 'mensual' o 'quincenal'
    })

    const persona2 = ref({
        ingresos: 0,
        periodo: 'mensual'
    })

    const costoTotal = ref(0)

    // Computed para normalizar ingresos a mensual
    const ingresosMensualesPersona1 = computed(() => {
        return persona1.value.periodo === 'quincenal'
            ? persona1.value.ingresos * 2
            : persona1.value.ingresos
    })

    const ingresosMensualesPersona2 = computed(() => {
        return persona2.value.periodo === 'quincenal'
            ? persona2.value.ingresos * 2
            : persona2.value.ingresos
    })

    // Computed para calcular totales
    const totalIngresosMensuales = computed(() => {
        return ingresosMensualesPersona1.value + ingresosMensualesPersona2.value
    })

    const porcentajePersona1 = computed(() => {
        if (totalIngresosMensuales.value === 0) return 0
        return (ingresosMensualesPersona1.value / totalIngresosMensuales.value) * 100
    })

    const porcentajePersona2 = computed(() => {
        if (totalIngresosMensuales.value === 0) return 0
        return (ingresosMensualesPersona2.value / totalIngresosMensuales.value) * 100
    })

    const montoPersona1 = computed(() => {
        if (totalIngresosMensuales.value === 0) return 0
        return (ingresosMensualesPersona1.value / totalIngresosMensuales.value) * costoTotal.value
    })

    const montoPersona2 = computed(() => {
        if (totalIngresosMensuales.value === 0) return 0
        return (ingresosMensualesPersona2.value / totalIngresosMensuales.value) * costoTotal.value
    })

    // Acciones
    const actualizarPersona1 = (datos) => {
        persona1.value = { ...persona1.value, ...datos }
    }

    const actualizarPersona2 = (datos) => {
        persona2.value = { ...persona2.value, ...datos }
    }

    const actualizarCostoTotal = (costo) => {
        costoTotal.value = costo
    }

    const limpiarDatos = () => {
        persona1.value = { ingresos: 0, periodo: 'mensual' }
        persona2.value = { ingresos: 0, periodo: 'mensual' }
        costoTotal.value = 0
    }

    return {
        // Estado
        persona1,
        persona2,
        costoTotal,
        // Computed
        ingresosMensualesPersona1,
        ingresosMensualesPersona2,
        totalIngresosMensuales,
        porcentajePersona1,
        porcentajePersona2,
        montoPersona1,
        montoPersona2,
        // Acciones
        actualizarPersona1,
        actualizarPersona2,
        actualizarCostoTotal,
        limpiarDatos
    }
})