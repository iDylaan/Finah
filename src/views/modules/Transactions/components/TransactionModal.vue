<template>
    <Dialog
        v-model:visible="modalsStore.transactionModalVisible"
        :header="modalTitle"
        :modal="true"
        :closable="!isLoading"
        :closeOnEscape="!isLoading"
        :dismissableMask="!isLoading"
        :draggable="false"
        class="w-full max-w-2xl mx-4"
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
                :cuentas="cuentas"
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
import { useModalsStore } from '@/stores/ui-modals.js';
import IngresoForm from './IngresoForm.vue';
import GastoForm from './GastoForm.vue';

// Composables
const toast = useToast();

// Stores
const accountsStore = useAccountsStore();
const categoriesStore = useCategoriesStore();
const levelsStore = useLevelStore();
const transactionsStore = useTransactionsStore();
const modalsStore = useModalsStore();

// State
const isLoading = ref(false);
const isLoadingData = ref(false);

// Datos
const cuentas = computed(() => accountsStore.accounts);
const categoryGroups = computed(() => categoriesStore.categoryGroups);
const niveles = computed(() => levelsStore.levels);

// Categorías filtradas para ingresos (TODO: filtrar por tipo cuando esté implementado)
// Por ahora retorna todos los grupos
const categoriasIngreso = computed(() => categoryGroups.value);

// Refs de formularios
const ingresoFormRef = ref(null);
const gastoFormRef = ref(null);

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
};

const handleSubmit = async () => {
    try {
        let formRef = null;
        
        // Obtener el formulario activo
        if (modalsStore.transactionModalType === 'ingreso') {
            formRef = ingresoFormRef.value;
        } else if (modalsStore.transactionModalType === 'gasto') {
            formRef = gastoFormRef.value;
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
        const transactionData = {
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

        console.log('📤 Enviando datos de transacción:', transactionData);

        // Crear según tipo
        if (modalsStore.transactionModalType === 'ingreso') {
            await transactionsStore.createIngreso(transactionData, { toast });
        } else if (modalsStore.transactionModalType === 'gasto') {
            await transactionsStore.createGasto(transactionData, { toast });
        }

        // Refrescar datos de cuentas
        await accountsStore.fetchAccountsWithDetails({ toast, force: true });

        // Cerrar modal
        handleClose();

    } catch (error) {
        console.error('Error en handleSubmit:', error);
    } finally {
        isLoading.value = false;
    }
};
</script>
