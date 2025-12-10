<template>
    <Dialog
        v-model:visible="modalsStore.transactionModalVisible"
        :header="modalTitle"
        :modal="true"
        :closable="!isLoading"
        :closeOnEscape="!isLoading"
        :dismissableMask="!isLoading"
        :draggable="false"
        :style="{ width: '95vw', maxWidth: '42rem' }"
        :breakpoints="{ '768px': '100vw' }"
        :contentStyle="{ maxHeight: 'calc(100vh - 120px)', overflowY: 'auto' }"
        class="mobile-fullscreen-dialog"
        @hide="handleClose"
    >
        <template #header>
            <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-lg flex items-center justify-center" :class="headerIconClass">
                    <span class="material-symbols-rounded text-white text-xl">{{ headerIcon }}</span>
                </div>
                <div>
                    <h3 class="text-lg font-semibold m-0">{{ modalTitle }}</h3>
                    <p class="text-sm text-surface-500 m-0">{{ modalSubtitle }}</p>
                </div>
            </div>
        </template>

        <!-- Loading State -->
        <div v-if="isLoadingData" class="flex justify-center items-center py-12">
            <ProgressSpinner />
        </div>

        <!-- Form Content -->
        <div v-else-if="modalsStore.transactionModalType === 'ingreso'">
            <IngresoForm 
                ref="ingresoFormRef"
                :cuentas="cuentasParaIngresos"
                :categoryGroups="categoryGroups"
                :niveles="niveles"
            />
        </div>

        <div v-else-if="modalsStore.transactionModalType === 'gasto'">
            <GastoForm 
                ref="gastoFormRef"
                :cuentas="cuentas"
                :categoryGroups="categoryGroups"
                :niveles="niveles"
            />
        </div>

        <div v-else-if="modalsStore.transactionModalType === 'transferencia'">
            <TransferenciaForm 
                ref="transferenciaFormRef"
                :cuentas="cuentas"
                :categoryGroups="categoryGroups"
                :preselectedAccountId="modalsStore.preselectedAccountId"
            />
        </div>

        <!-- Placeholder para otros tipos -->
        <div v-else class="text-center py-8 text-surface-500">
            <p>Formulario para {{ modalsStore.transactionModalType }} próximamente</p>
        </div>

        <template #footer>
            <div class="flex justify-end gap-2">
                <Button 
                    label="Cancelar" 
                    severity="secondary" 
                    outlined 
                    @click="handleClose"
                    :disabled="isLoading"
                />
                <Button 
                    :label="isLoading ? 'Guardando...' : 'Registrar'"
                    :loading="isLoading"
                    @click="handleSubmit"
                    :disabled="isLoading"
                />
            </div>
        </template>
    </Dialog>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useToast } from 'primevue/usetoast';
import { useAccountsStore } from '@/stores/accounts.js';
import { useCategoriesStore } from '@/stores/categories.js';
import { useLevelStore } from '@/stores/levels.js';
import { useTransactionsStore } from '@/stores/transactions.js';
import { useRecurringTransactionsStore } from '@/stores/recurring-transactions.js';
import { useModalsStore } from '@/stores/ui-modals.js';
import IngresoForm from './IngresoForm.vue';
import GastoForm from './GastoForm.vue';
import TransferenciaForm from './TransferenciaForm.vue';

// Composables
const toast = useToast();

// Stores
const accountsStore = useAccountsStore();
const categoriesStore = useCategoriesStore();
const levelsStore = useLevelStore();
const transactionsStore = useTransactionsStore();
const recurringStore = useRecurringTransactionsStore();
const modalsStore = useModalsStore();

// State
const isLoading = ref(false);
const isLoadingData = ref(false);

// Datos
const cuentas = computed(() => accountsStore.accounts);

// Cuentas filtradas para ingresos (excluye tarjetas de crédito)
const cuentasParaIngresos = computed(() => 
    accountsStore.accounts.filter(cuenta => cuenta.tipo !== 'credit_card')
);

const categoryGroups = computed(() => categoriesStore.categoryGroups);
const niveles = computed(() => levelsStore.levels);

// Categorías filtradas para ingresos (TODO: filtrar por tipo cuando esté implementado)
// Por ahora retorna todos los grupos
const categoriasIngreso = computed(() => categoryGroups.value);

// Refs de formularios
const ingresoFormRef = ref(null);
const gastoFormRef = ref(null);
const transferenciaFormRef = ref(null);

// Computed para header del modal
const modalTitle = computed(() => {
    const titles = {
        'ingreso': 'Registrar Ingreso',
        'gasto': 'Registrar Gasto',
        'transferencia': 'Registrar Transferencia'
    };
    return titles[modalsStore.transactionModalType] || 'Registrar Movimiento';
});

const modalSubtitle = computed(() => {
    const subtitles = {
        'ingreso': 'Registra un ingreso a tu cuenta',
        'gasto': 'Registra un gasto realizado',
        'transferencia': 'Transfiere dinero entre cuentas'
    };
    return subtitles[modalsStore.transactionModalType] || '';
});

const headerIcon = computed(() => {
    const icons = {
        'ingreso': 'paid',
        'gasto': 'receipt_long',
        'transferencia': 'send_money'
    };
    return icons[modalsStore.transactionModalType] || 'receipt';
});

const headerIconClass = computed(() => {
    const classes = {
        'ingreso': 'bg-green-500',
        'gasto': 'bg-red-500',
        'transferencia': 'bg-blue-500'
    };
    return classes[modalsStore.transactionModalType] || 'bg-surface-500';
});

// Watch para cargar datos cuando se abre el modal
watch(() => modalsStore.transactionModalVisible, (newValue) => {
    if (newValue) {
        loadData();
    }
}, { immediate: true });

// Cargar datos necesarios
const loadData = async () => {
    isLoadingData.value = true;
    try {
        await Promise.all([
            accountsStore.fetchAccountsWithDetails({ toast }),
            categoriesStore.fetchCategoryGroupsWithCategories({ toast }), // Cambiar a estructura anidada
            levelsStore.fetchLevels({ toast })
        ]);
    } catch (error) {
        console.error('Error cargando datos:', error);
        toast.add({
            severity: 'error',
            summary: 'Error',
            detail: 'No se pudieron cargar los datos necesarios',
            life: 5000
        });
    } finally {
        isLoadingData.value = false;
    }
};

// Handlers
const handleClose = () => {
    if (isLoading.value) return;
    
    // Cerrar modal usando el store
    modalsStore.closeTransactionModal();
    
    // Reset forms
    if (ingresoFormRef.value) {
        ingresoFormRef.value.reset();
    }
    if (gastoFormRef.value) {
        gastoFormRef.value.reset();
    }
    if (transferenciaFormRef.value) {
        transferenciaFormRef.value.reset();
    }
};

const handleSubmit = async () => {
    try {
        let formRef = null;
        
        // Obtener el formulario activo
        if (modalsStore.transactionModalType === 'ingreso') {
            formRef = ingresoFormRef.value;
        } else if (modalsStore.transactionModalType === 'gasto') {
            formRef = gastoFormRef.value;
        } else if (modalsStore.transactionModalType === 'transferencia') {
            formRef = transferenciaFormRef.value;
        }
        
        if (!formRef) {
            console.error('No se encontró el formulario');
            return;
        }

        // Validar
        if (!formRef.validate()) {
            toast.add({
                severity: 'warn',
                summary: 'Validación',
                detail: 'Por favor completa todos los campos requeridos',
                life: 3000
            });
            return;
        }

        isLoading.value = true;

        // Obtener datos del formulario
        const formData = formRef.formData;

        // Preparar datos para enviar
        let transactionData;
        
        if (modalsStore.transactionModalType === 'transferencia') {
            // Datos específicos para transferencia
            transactionData = {
                cuenta_origen_id: formData.cuenta_origen_id,
                cuenta_destino_id: formData.cuenta_destino_id,
                categoria_id: formData.categoria_id,
                monto: formData.monto,
                fecha_ocurrencia: formData.fecha_ocurrencia instanceof Date 
                    ? formData.fecha_ocurrencia.toISOString().split('T')[0]
                    : formData.fecha_ocurrencia,
                descripcion: formData.descripcion,
                metadatos: {}
            };
        } else {
            // Datos para ingreso/gasto
            transactionData = {
                cuenta_id: formData.cuenta_id,
                categoria_id: formData.categoria_id,
                nivel_id: formData.nivel_id,
                monto: formData.monto,
                fecha_ocurrencia: formData.fecha_ocurrencia instanceof Date 
                    ? formData.fecha_ocurrencia.toISOString().split('T')[0]
                    : formData.fecha_ocurrencia,
                descripcion: formData.descripcion,
                metadatos: {}
            };
        }

        console.log('📤 Enviando datos de transacción:', transactionData);

        // Crear según tipo
        try {
            if (modalsStore.transactionModalType === 'ingreso') {
                await transactionsStore.createIngreso(transactionData, { toast });
            } else if (modalsStore.transactionModalType === 'gasto') {
                // Si es gasto y tiene MSI configurado
                if (formData.diferirMSI && formData.numeroMeses) {
                    console.log('🛍️ Creando gasto con MSI...');
                    
                    const mesesYaPagados = formData.mesesYaPagados || 0;
                    
                    // Crear el MSI directamente (NO crear transacción de gasto)
                    // El MSI maneja todo a través de sus cuotas programadas
                    
                    // Calcular meses finales (personalizado o del dropdown)
                    const mesesFinales = formData.numeroMeses === 'personalizado' 
                        ? formData.mesesPersonalizados 
                        : formData.numeroMeses;
                    
                    const msiData = {
                        cuenta_id: formData.cuenta_id,
                        categoria_id: formData.categoria_id,
                        nombre: formData.nombreMSI || transactionData.descripcion || 'Pago diferido sin nombre',
                        descripcion: transactionData.descripcion,
                        monto_total: formData.monto,
                        numero_meses: mesesFinales,
                        meses_ya_pagados: mesesYaPagados
                    };
                    
                    // Agregar monto personalizado si no es automático
                    if (formData.tipoMonto === 'manual' && formData.montoPorMes) {
                        msiData.monto_por_mes = formData.montoPorMes;
                    } else if (formData.tipoMonto === 'redondeado') {
                        msiData.monto_por_mes = Math.ceil(formData.monto / mesesFinales);
                    }
                    
                    await recurringStore.createMSI(msiData, { toast });
                    
                    // Recargar la lista de MSI
                    await recurringStore.fetchRecurringTransactions({ toast });
                } else {
                    // Gasto normal sin MSI
                    await transactionsStore.createGasto(transactionData, { toast });
                }
            } else if (modalsStore.transactionModalType === 'transferencia') {
                await transactionsStore.createTransferencia(transactionData, { toast });
            }

            console.log('✅ Transacción creada exitosamente, cerrando modal...');

            // Refrescar datos de cuentas (no bloqueante)
            accountsStore.fetchAccountsWithDetails({ toast, force: true }).catch(err => {
                console.error('Error refrescando cuentas:', err);
            });

            // Establecer loading a false ANTES de cerrar el modal
            isLoading.value = false;

            // Cerrar modal
            handleClose();
            console.log('🚪 Modal cerrado');
        } catch (error) {
            // El error ya fue mostrado en el toast por la función create*
            // Solo logueamos para debugging
            console.error('❌ Error al crear transacción:', error);
            // No cerramos el modal para que el usuario pueda corregir
            isLoading.value = false;
        }

    } catch (error) {
        console.error('Error en handleSubmit:', error);
        toast.add({
            severity: 'error',
            summary: 'Error',
            detail: 'Ocurrió un error inesperado',
            life: 5000
        });
        isLoading.value = false;
    }
};
</script>
