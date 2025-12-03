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
            <ProgressBar :value="porcentajeUso || 0" :showValue="false" :class="getProgressBarClass(porcentajeUso)" :pt="{
                value: { style: `background: ${getUsageColor(porcentajeUso)}` }
            }" />
            <div class="flex justify-between text-xs text-surface-600 dark:text-surface-400 mt-1">
                <span>{{ formatCurrency(montoUtilizado || 0) }} usado</span>
                <span>{{ formatCurrency(card.credito_disponible || 0) }} disponible</span>
            </div>
        </div>

        <!-- Información del periodo y pagos -->
        <div v-if="!loading" class="space-y-2">
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

            <!-- Información de pagos -->
            <div class="p-2 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg">
                <div class="text-xs text-green-700 dark:text-green-400 mb-1">Pago total</div>
                <div class="text-sm font-bold text-green-800 dark:text-green-300">
                    {{ formatCurrency(montoUtilizado || 0) }}
                </div>
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
import { formatDate } from '@/lib/utils.js';
import { diasHasta, formatCurrency as formatMoneda } from '@/utils/misc.js';
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

const accountsStore = useAccountsStore();
const info = ref(null);
const loading = ref(true);

// Calcular días usando las fechas que ya vienen en card
const diasHastaCorte = computed(() => {
    return props.card.proxima_fecha_corte ? diasHasta(props.card.proxima_fecha_corte) : null;
});

const diasHastaPago = computed(() => {
    return props.card.proxima_fecha_pago ? diasHasta(props.card.proxima_fecha_pago) : null;
});

const porcentajeUso = computed(() => {
    return porcentajeUsoCredito(props.card.limite_credito, props.card.credito_disponible);
});

const montoUtilizado = computed(() => {
    return montoUsado(props.card.limite_credito, props.card.credito_disponible);
});

const pagoMinimo = computed(() => {
    return calcularPagoMinimo(montoUtilizado.value, props.card.porcentaje_pago_minimo || 5);
});

const enPeligro = computed(() => {
    return diasHastaPago.value <= 3 || porcentajeUso.value >= 90;
});

const requiereAtencion = computed(() => {
    return diasHastaPago.value <= 7 || porcentajeUso.value >= 70;
});

// Cargar información de la tarjeta (solo gastos del periodo)
const loadCardInfo = async () => {
    loading.value = true;
    try {
        // Solo obtener gastos del periodo
        if (props.card.dia_corte && props.card.dia_pago) {
            const gastosPeriodo = await accountsStore.calcularGastosPeriodoActual(
                props.card.id,
                props.card.dia_corte,
                props.card.dia_pago
            );
            info.value = { gastosPeriodo };
        } else {
            info.value = { gastosPeriodo: 0 };
        }
    } catch (error) {
        console.error('Error cargando info de tarjeta:', error);
        info.value = { gastosPeriodo: 0 };
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
</script>

<style scoped>
.credit-card-info {
    width: 100%;
}

/* Estilos para ProgressBar */
:deep(.progress-danger .p-progressbar-value) {
    background: var(--red-500);
}

:deep(.progress-warning .p-progressbar-value) {
    background: var(--orange-500);
}

:deep(.progress-info .p-progressbar-value) {
    background: var(--yellow-500);
}

:deep(.progress-success .p-progressbar-value) {
    background: var(--green-500);
}
</style>
