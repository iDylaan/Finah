<template>
    <div class="credit-card-info">
        <!-- Barra de progreso de uso -->
        <div class="mb-3">
            <div class="flex justify-between items-center mb-2">
                <span class="text-sm font-medium">Uso del crédito</span>
                <span class="text-sm font-semibold" :class="getUsageColorClass(porcentajeUso)">
                    {{ formatPercentage(porcentajeUso) }}
                </span>
            </div>
            <ProgressBar
                :value="Math.round(porcentajeUso)"
                :showValue="false"
                :severity="getSeverityByUsage(porcentajeUso)"
                style="height: 10px"
            />
            <div class="flex justify-between text-xs text-surface-600 dark:text-surface-400 mt-1">
                <span>{{ formatCurrency(montoUtilizado || 0) }} usado</span>
                <span>{{ formatCurrency(card.credito_disponible || 0) }} disponible</span>
            </div>
        </div>

        <!-- Información del periodo y pagos -->
        <div v-if="!loading" class="space-y-2">
            <!-- Periodo actual con fechas -->
            <div v-if="fechasPeriodo" class="p-2 bg-primary-50 dark:bg-primary-900/20 border border-primary-200 dark:border-primary-800 rounded-lg">
                <div class="flex items-center justify-between mb-1">
                    <div class="flex items-center gap-2">
                        <span class="material-symbols-outlined text-lg text-primary">calendar_month</span>
                        <span class="text-xs font-semibold text-primary-700 dark:text-primary-400">Periodo Actual</span>
                    </div>
                </div>
                <div class="text-xs text-primary-600 dark:text-primary-300">
                    {{ formatDate(fechasPeriodo.periodo_actual.inicio) }} - {{ formatDate(fechasPeriodo.periodo_actual.fin) }}
                </div>
            </div>

            <!-- Gastos del periodo actual -->
            <div class="flex items-center justify-between p-2 bg-surface-50 dark:bg-surface-800/50 rounded-lg">
                <div class="flex items-center gap-2">
                    <span class="material-symbols-outlined text-lg text-primary">receipt_long</span>
                    <span class="text-sm">Gastos del periodo</span>
                </div>
                <span class="text-sm font-semibold text-primary">
                    {{ formatCurrency(info?.gastosPeriodo || 0) }}
                </span>
            </div>

            <!-- Días hasta el corte -->
            <div v-if="card.proxima_fecha_corte" class="flex items-center justify-between p-2 rounded-lg"
                :class="getBgClassByDays(diasHastaCorte, 'corte')">
                <div class="flex items-center gap-2">
                    <span class="material-symbols-outlined text-lg" :class="getSeverityIconClass(diasHastaCorte)">
                        schedule
                    </span>
                    <span class="text-sm">{{ getMensajeCorte(diasHastaCorte) }}</span>
                </div>
                <span class="text-sm font-semibold">
                    {{ formatDate(card.proxima_fecha_corte) }}
                </span>
            </div>

            <!-- Días hasta el pago -->
            <div v-if="card.proxima_fecha_pago" class="flex items-center justify-between p-2 rounded-lg"
                :class="getBgClassByDays(diasHastaPago, 'pago')">
                <div class="flex items-center gap-2">
                    <span class="material-symbols-outlined text-lg" :class="getSeverityIconClass(diasHastaPago)">
                        {{ diasHastaPago <= 3 ? 'error' : 'event' }} </span>
                            <span class="text-sm">{{ getMensajePago(diasHastaPago) }}</span>
                </div>
                <span class="text-sm font-semibold">
                    {{ formatDate(card.proxima_fecha_pago) }}
                </span>
            </div>

            <!-- Alerta de deuda arrastrada (si existe) -->
            <div v-if="desglose?.saldo_arrastre > 0" 
                 class="p-2 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
                <div class="flex items-center justify-between">
                    <div class="flex items-center gap-1.5">
                        <span class="material-symbols-outlined text-lg text-red-600 dark:text-red-400">warning</span>
                        <span class="text-xs font-semibold text-red-700 dark:text-red-300">Deuda arrastrada</span>
                    </div>
                    <span class="text-sm font-bold text-red-800 dark:text-red-200">
                        {{ formatCurrency(desglose.saldo_arrastre) }}
                    </span>
                </div>
                <p class="text-xs text-red-600 dark:text-red-400 mt-1">
                    No pagaste el total del periodo anterior
                </p>
            </div>

            <!-- Información de pagos del periodo actual con desglose -->
            <div class="p-3 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg space-y-2">
                <div class="text-xs text-green-700 dark:text-green-400 font-semibold">
                    {{ desglose?.saldo_arrastre > 0 ? 'Total a pagar' : 'Saldo del periodo actual' }}
                </div>
                <div class="text-lg font-bold text-green-800 dark:text-green-300">
                    {{ formatCurrency(desglose?.total_a_pagar || desglose?.saldo_periodo_actual || 0) }}
                </div>
                
                <!-- Desglose detallado -->
                <div class="pt-2 border-t border-green-200 dark:border-green-800 space-y-1.5">
                    <!-- Mostrar arrastre si existe -->
                    <div v-if="desglose?.saldo_arrastre > 0" class="flex justify-between items-center text-xs">
                        <span class="text-red-600 dark:text-red-400 font-semibold">Deuda arrastrada:</span>
                        <span class="font-semibold text-red-700 dark:text-red-300">
                            {{ formatCurrency(desglose.saldo_arrastre) }}
                        </span>
                    </div>
                    <div class="flex justify-between items-center text-xs">
                        <span class="text-green-600 dark:text-green-400">Gastos periodo actual:</span>
                        <span class="font-semibold text-green-700 dark:text-green-300">
                            {{ formatCurrency(desglose?.saldo_periodo_actual || 0) }}
                        </span>
                    </div>
                    
                    <div v-if="desglose?.saldo_arrastre > 0" class="flex justify-between items-center text-xs pt-1.5 border-t border-green-200 dark:border-green-800">
                        <span class="text-green-700 dark:text-green-300 font-bold">Total a pagar:</span>
                        <span class="font-bold text-green-800 dark:text-green-200">
                            {{ formatCurrency(desglose.total_a_pagar) }}
                        </span>
                    </div>
                    <div class="pt-1 border-t border-green-200 dark:border-green-800">
                        <div class="flex justify-between items-center text-xs">
                            <span class="text-green-600 dark:text-green-400">Deuda no diferida:</span>
                            <span class="font-semibold text-green-700 dark:text-green-300">
                                {{ formatCurrency(desglose?.deuda_no_diferida || 0) }}
                            </span>
                        </div>
                        <div class="flex justify-between items-center text-xs mt-1">
                            <span class="text-green-600 dark:text-green-400">Cuota MSI este periodo:</span>
                            <span class="font-semibold text-green-700 dark:text-green-300">
                                {{ formatCurrency(desglose?.cuota_msi_periodo || 0) }}
                            </span>
                        </div>
                        <div class="flex justify-between items-center text-xs text-green-500 dark:text-green-600 mt-1">
                            <span>Total MSI pendiente:</span>
                            <span>{{ formatCurrency(desglose?.total_msi_pendiente || 0) }}</span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Información del periodo siguiente -->
            <div class="p-3 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg space-y-2">
                <div class="flex items-center justify-between">
                    <div class="text-xs text-blue-700 dark:text-blue-400 font-semibold">Proyección periodo siguiente</div>
                    <div v-if="fechasPeriodo" class="text-xs text-blue-600 dark:text-blue-300">
                        {{ formatDate(fechasPeriodo.periodo_siguiente.inicio) }} - {{ formatDate(fechasPeriodo.periodo_siguiente.fin) }}
                    </div>
                </div>
                
                <!-- Proyecciones lado a lado -->
                <div class="flex items-center gap-3">
                    <!-- Proyección base (sin programados) -->
                    <div class="flex-1">
                        <div class="text-lg font-bold text-blue-800 dark:text-blue-300">
                            {{ formatCurrency(proyeccionBase) }}
                        </div>
                    </div>
                    
                    <!-- Proyección con programados (menor opacidad) -->
                    <div v-if="desgloseSiguiente?.gastos_programados > 0" class="flex-shrink-0 opacity-60">
                        <div class="text-xs text-blue-600 dark:text-blue-400 mb-0.5">Con programados:</div>
                        <div class="text-base font-semibold text-blue-700 dark:text-blue-300">
                            {{ formatCurrency(desgloseSiguiente?.proyeccion_total || 0) }}
                        </div>
                    </div>
                </div>
                
                <!-- Desglose siguiente periodo -->
                <div class="pt-2 border-t border-blue-200 dark:border-blue-800 space-y-1.5">
                    <div class="flex justify-between items-center text-xs">
                        <span class="text-blue-600 dark:text-blue-400">Cuota MSI siguiente periodo:</span>
                        <span class="font-semibold text-blue-700 dark:text-blue-300">
                            {{ formatCurrency(desgloseSiguiente?.cuota_msi_periodo || 0) }}
                        </span>
                    </div>
                    <div class="flex justify-between items-center text-xs">
                        <span class="text-blue-600 dark:text-blue-400">Gastos futuros registrados:</span>
                        <span class="font-semibold text-blue-700 dark:text-blue-300">
                            {{ formatCurrency(desgloseSiguiente?.gastos_futuros_registrados || 0) }}
                        </span>
                    </div>
                    
                    <!-- Gastos programados del periodo siguiente -->
                    <div v-if="desgloseSiguiente?.gastos_programados > 0" class="flex justify-between items-center text-xs opacity-60">
                        <div class="flex items-center gap-1">
                            <span class="text-blue-600 dark:text-blue-400">Gastos programados (simulación):</span>
                        </div>
                        <span class="font-semibold text-blue-700 dark:text-blue-300">
                            {{ formatCurrency(desgloseSiguiente.gastos_programados) }}
                        </span>
                    </div>
                </div>
            </div>

            <!-- Botones de acción -->
            <div class="flex flex-col gap-2">
                <Button 
                    v-if="info?.gastosPeriodo > 0"
                    label="Realizar Pago" 
                    icon="pi pi-credit-card"
                    class="w-full"
                    severity="success"
                    @click="emit('open-payment-modal')"
                />
                <Button 
                    label="Ver Pagos Diferidos" 
                    icon="pi pi-list"
                    class="w-full"
                    severity="secondary"
                    outlined
                    size="small"
                    @click="emit('view-msi')"
                />
            </div>

            <!-- Badge de alerta si está en peligro -->
            <Message v-if="enPeligro" severity="error" :closable="false" class="text-xs p-2 mt-2">
                <template #icon>
                    <span class="material-symbols-outlined text-sm">warning</span>
                </template>
                ¡Atención! Pago próximo o crédito casi al límite
            </Message>

            <Message v-else-if="requiereAtencion" severity="warn" :closable="false" class="text-xs p-2 mt-2">
                <template #icon>
                    <span class="material-symbols-outlined text-sm">info</span>
                </template>
                Revisa tu crédito y fecha de pago próxima
            </Message>
        </div>

        <!-- Loading state -->
        <div v-else class="flex justify-center py-4">
            <ProgressSpinner style="width: 30px; height: 30px" strokeWidth="4" />
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted, watch, computed } from 'vue';
import { useAccountsStore } from '@/stores/accounts.js';
import { formatDate, diasHasta, formatCurrency as formatMoneda } from '@/lib/utils.js';
import {
    obtenerMensajePago,
    obtenerMensajeCorte,
    obtenerSeveridadPorDias,
    obtenerSeveridadPorUso,
    porcentajeUsoCredito,
    montoUsado,
    calcularPagoMinimo
} from '@/lib/creditCardUtils.js';

const props = defineProps({
    card: {
        type: Object,
        required: true
    }
});

const emit = defineEmits(['open-payment-modal', 'configure-msi', 'view-msi']);

const accountsStore = useAccountsStore();
const info = ref(null);
const resumenPeriodos = ref(null);
const loading = ref(true);

// Calcular días usando las fechas que ya vienen en card
const diasHastaCorte = computed(() => {
    return props.card.proxima_fecha_corte ? diasHasta(props.card.proxima_fecha_corte) : null;
});

const diasHastaPago = computed(() => {
    return props.card.proxima_fecha_pago ? diasHasta(props.card.proxima_fecha_pago) : null;
});

const porcentajeUso = computed(() => {
    const limite = parseFloat(props.card.limite_credito) || 0;
    const disponible = parseFloat(props.card.credito_disponible) || 0;
    return porcentajeUsoCredito(limite, disponible);
});

const montoUtilizado = computed(() => {
    const limite = parseFloat(props.card.limite_credito) || 0;
    const disponible = parseFloat(props.card.credito_disponible) || 0;
    return montoUsado(limite, disponible);
});

const pagoMinimo = computed(() => {
    return calcularPagoMinimo(montoUtilizado.value, props.card.porcentaje_pago_minimo || 5);
});

// Proyección base del periodo siguiente (sin gastos programados)
const proyeccionBase = computed(() => {
    const cuotaMSI = desgloseSiguiente.value?.cuota_msi_periodo || 0;
    const gastosFuturos = desgloseSiguiente.value?.gastos_futuros_registrados || 0;
    return cuotaMSI + gastosFuturos;
});

// Desglose de deuda del periodo actual
const desglose = computed(() => {
    return resumenPeriodos.value?.desglose_deuda || null;
});

// Desglose del siguiente periodo
const desgloseSiguiente = computed(() => {
    return resumenPeriodos.value?.desglose_siguiente_periodo || null;
});

// Fechas de los periodos
const fechasPeriodo = computed(() => {
    return resumenPeriodos.value?.fechas || null;
});

const enPeligro = computed(() => {
    return diasHastaPago.value <= 3 || porcentajeUso.value >= 90;
});

const requiereAtencion = computed(() => {
    return diasHastaPago.value <= 7 || porcentajeUso.value >= 70;
});

// Cargar información completa de periodos de la tarjeta
const loadCardInfo = async () => {
    loading.value = true;
    try {
        if (props.card.dia_corte && props.card.dia_pago) {
            // Obtener resumen completo de periodos (actual y siguiente)
            const resumen = await accountsStore.obtenerResumenPeriodosTarjeta(props.card.id);
            resumenPeriodos.value = resumen;
            
            // Mantener compatibilidad con info anterior
            info.value = { 
                gastosPeriodo: resumen?.periodo_actual?.total || 0,
                gastosPeriodoSiguiente: resumen?.periodo_siguiente?.total || 0
            };
        } else {
            resumenPeriodos.value = null;
            info.value = { gastosPeriodo: 0, gastosPeriodoSiguiente: 0 };
        }
    } catch (error) {
        console.error('Error cargando info de tarjeta:', error);
        resumenPeriodos.value = null;
        info.value = { gastosPeriodo: 0, gastosPeriodoSiguiente: 0 };
    } finally {
        loading.value = false;
    }
};

// Formatters
const formatCurrency = (amount) => formatMoneda(amount);
const formatPercentage = (value) => `${Math.round(value || 0)}%`;

const getMensajePago = (dias) => obtenerMensajePago(dias);
const getMensajeCorte = (dias) => obtenerMensajeCorte(dias);

// Colores según uso del crédito
const getUsageColor = (porcentaje) => {
    if (porcentaje >= 90) return 'var(--red-500)';
    if (porcentaje >= 70) return 'var(--orange-500)';
    if (porcentaje >= 50) return 'var(--yellow-500)';
    return 'var(--green-500)';
};

const getUsageColorClass = (porcentaje) => {
    if (porcentaje >= 90) return 'text-red-600 dark:text-red-400';
    if (porcentaje >= 70) return 'text-orange-600 dark:text-orange-400';
    if (porcentaje >= 50) return 'text-yellow-600 dark:text-yellow-400';
    return 'text-green-600 dark:text-green-400';
};

const getProgressBarClass = (porcentaje) => {
    if (porcentaje >= 90) return 'progress-danger';
    if (porcentaje >= 70) return 'progress-warning';
    if (porcentaje >= 50) return 'progress-info';
    return 'progress-success';
};

// Severity para ProgressBar de PrimeVue
const getSeverityByUsage = (porcentaje) => {
    if (porcentaje >= 90) return 'danger';
    if (porcentaje >= 70) return 'warn';
    if (porcentaje >= 50) return 'info';
    return 'success';
};

// Clases de fondo según días restantes
const getBgClassByDays = (dias, tipo) => {
    const severidad = obtenerSeveridadPorDias(dias);

    if (severidad === 'peligro') {
        return 'bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800';
    }
    if (severidad === 'advertencia') {
        return 'bg-orange-50 dark:bg-orange-900/20 border border-orange-200 dark:border-orange-800';
    }
    if (severidad === 'informacion') {
        return 'bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800';
    }

    return 'bg-surface-50 dark:bg-surface-800/50';
};

const getSeverityIconClass = (dias) => {
    const severidad = obtenerSeveridadPorDias(dias);

    if (severidad === 'peligro') return 'text-red-600 dark:text-red-400';
    if (severidad === 'advertencia') return 'text-orange-600 dark:text-orange-400';
    if (severidad === 'informacion') return 'text-blue-600 dark:text-blue-400';

    return 'text-surface-600 dark:text-surface-400';
};

// Cargar al montar
onMounted(() => {
    loadCardInfo();
});

// Recargar si cambia la tarjeta
watch(() => props.card, () => {
    loadCardInfo();
}, { deep: true });

// Recargar si cambia el ID (para detectar actualizaciones)
watch(() => props.card?.id, (newId, oldId) => {
    if (newId && newId === oldId) {
        // Mismo ID, pero puede haber cambios, recargar
        loadCardInfo();
    }
});

// Exponer método para recarga manual
defineExpose({
    loadCardInfo
});
</script>

<style scoped>
.credit-card-info {
    width: 100%;
}
</style>
