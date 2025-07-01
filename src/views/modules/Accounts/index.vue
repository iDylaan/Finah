<template>
    <div class="p-6 max-w-5xl mx-auto">
        <!-- Header -->
        <div class="flex justify-between items-center mb-6">
            <div>
                <h1 class="text-3xl font-bold text-surface-900 dark:text-surface-0 mb-2">
                    Mis Cuentas
                </h1>
                <p class="text-surface-600 dark:text-surface-400">
                    Gestiona tus cuentas bancarias, tarjetas de crédito y efectivo
                </p>
            </div>

            <div class="flex gap-2">
                <Button icon="pi pi-refresh" @click="refreshData" :loading="accountsStore.loading" 
                    severity="secondary" outlined size="small" />
                <Button icon="pi pi-plus" @click="handleNewAccount" :disabled="accountsStore.loading"
                    severity="success" outlined size="small" label="Nueva Cuenta" />
            </div>
        </div>

        <!-- Loading State -->
        <div v-if="accountsStore.loading && accounts.length === 0" class="flex justify-center items-center py-12">
            <ProgressSpinner />
        </div>

        <!-- Content -->
        <div v-else-if="accounts.length > 0" class="space-y-4">
            <Card v-for="account in accounts" :key="account.id"
                class="bg-surface-0 dark:bg-surface-800 border border-surface-200 dark:border-surface-700 rounded-lg overflow-hidden hover:shadow-lg transition-shadow duration-200">
                
                <template #content>
                    <div class="flex items-center gap-4 p-4">
                        <!-- Icono de la cuenta/banco -->
                        <div class="w-12 h-12 rounded-lg flex items-center justify-center flex-shrink-0 shadow-sm"
                            :style="{ backgroundColor: getAccountColor(account) }">
                            <i :class="getAccountIcon(account)" class="text-white text-lg"></i>
                        </div>

                        <!-- Info de la cuenta -->                            <div class="flex-1">
                            <h3 class="text-lg font-semibold text-surface-900 dark:text-surface-0 mb-1">
                                {{ account.nombre }}
                            </h3>
                            <div class="flex items-center gap-2 text-sm text-surface-600 dark:text-surface-400">
                                <span>{{ getAccountTypeLabel(account.tipo) }}</span>
                                <span v-if="account.banco">• {{ account.banco.nombre }}</span>
                                <span v-if="account.metadatos?.last4">• ••{{ account.metadatos.last4 }}</span>
                            </div>
                        </div>

                        <!-- Información de saldo/crédito -->
                        <div class="text-right">
                            <div v-if="account.tipo === 'credit_card' && account.tarjeta_credito">
                                <p class="text-lg font-bold text-surface-900 dark:text-surface-0">
                                    {{ formatCurrency(account.tarjeta_credito.credito_disponible) }}
                                </p>
                                <p class="text-xs text-surface-500">
                                    disponible de {{ formatCurrency(account.tarjeta_credito.limite_credito) }}
                                </p>
                                <div class="mt-1 flex flex-wrap gap-1">
                                    <!-- Badges para información básica -->
                                    <Badge :value="`Pago: ${account.tarjeta_credito.dia_pago}`" severity="info" size="small" />
                                    
                                    <!-- Badges opcionales solo si tienen datos -->
                                    <Badge v-if="account.tarjeta_credito.porcentaje_cat" 
                                           :value="`CAT: ${account.tarjeta_credito.porcentaje_cat}%`" 
                                           severity="warning" size="small" />
                                    
                                    <Badge v-if="account.tarjeta_credito.anualidad === 0" 
                                           value="Sin anualidad" severity="success" size="small" />
                                    
                                    <Badge v-if="account.tarjeta_credito.anualidad > 0" 
                                           :value="`Anualidad: ${formatCurrency(account.tarjeta_credito.anualidad)}`" 
                                           severity="warning" size="small" />
                                    
                                    <Badge v-if="account.tarjeta_credito.porcentaje_cashback" 
                                           :value="`Cashback: ${account.tarjeta_credito.porcentaje_cashback}%`" 
                                           severity="success" size="small" />
                                </div>
                            </div>
                            <div v-else>
                                <p class="text-lg font-bold text-surface-900 dark:text-surface-0">
                                    {{ formatCurrency(account.saldo) }}
                                </p>
                                <p class="text-xs text-surface-500">saldo actual</p>
                            </div>
                        </div>

                        <!-- Menú de acciones -->
                        <div class="flex items-center">
                            <Button icon="pi pi-ellipsis-v" severity="secondary" rounded text
                                @click="(event) => toggleAccountMenu(event, account.id)" />

                            <Menu :ref="(el) => setAccountMenuRef(el, account.id)" 
                                :id="`account_menu_${account.id}`"
                                :model="getAccountMenuItems(account)" popup />
                        </div>
                    </div>
                </template>
            </Card>
        </div>

        <!-- Empty State -->
        <Card v-else class="backdrop-blur-md bg-surface-0/80 dark:bg-surface-800/80 border border-surface-200/30 dark:border-surface-700/30">
            <template #content>
                <div class="text-center py-12">
                    <div class="mb-6">
                        <i class="pi pi-credit-card text-6xl text-surface-300 dark:text-surface-600"></i>
                    </div>
                    <h3 class="text-xl font-semibold text-surface-700 dark:text-surface-300 mb-2">
                        No hay cuentas registradas
                    </h3>
                    <p class="text-surface-500 dark:text-surface-400 mb-6 max-w-md mx-auto">
                        Registra tu primera cuenta bancaria, tarjeta o efectivo para comenzar
                    </p>
                    <Button label="Crear Primera Cuenta" icon="pi pi-plus" @click="handleNewAccount" />
                </div>
            </template>
        </Card>

        <!-- Modal Component -->
        <AccountForm 
            v-model:visible="showAccountModal" 
            :is-edit="modalEditMode"
            :edit-account-id="editingAccountId"
            :accounts="accounts"
            :banks="accountsStore.banks"
            :is-loading="accountsStore.loading" 
            @submit="handleAccountSubmit" 
            @close="handleModalClose" />
    </div>
</template>

<script setup>
// IMPORTS
import { ref, onMounted, computed } from 'vue';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import { useAccountsStore } from '@/stores/accounts.js';
import AccountForm from './components/AccountForm.vue';

// STORES & COMPOSABLES
const toast = useToast();
const confirm = useConfirm();
const accountsStore = useAccountsStore();

// VARIABLES
const isInitialLoad = ref(true);
const accounts = computed(() => accountsStore.accounts);
const accountMenuRefs = ref({});

// MODAL STATE
const showAccountModal = ref(false);
const modalEditMode = ref(false);
const editingAccountId = ref(null);

// FUNCTIONS
const getAccountTypeLabel = (type) => {
    const types = {
        'cash': 'Efectivo',
        'bank': 'Cuenta Bancaria',
        'debit_card': 'Tarjeta de Débito',
        'credit_card': 'Tarjeta de Crédito'
    };
    return types[type] || type;
};

const getAccountColor = (account) => {
    if (account.banco?.color) {
        return account.banco.color;
    }
    
    const colors = {
        'cash': '#10b981',
        'bank': '#3b82f6',
        'debit_card': '#8b5cf6',
        'credit_card': '#f59e0b'
    };
    
    return colors[account.tipo] || '#6366f1';
};

const getAccountIcon = (account) => {
    if (account.banco?.nombre_icono && account.banco?.libreria_icono === 'primevue') {
        return account.banco.nombre_icono;
    }
    
    const icons = {
        'cash': 'pi pi-dollar',
        'bank': 'pi pi-building',
        'debit_card': 'pi pi-credit-card',
        'credit_card': 'pi pi-credit-card'
    };
    
    return icons[account.tipo] || 'pi pi-wallet';
};

const formatCurrency = (amount) => {
    return new Intl.NumberFormat('es-MX', {
        style: 'currency',
        currency: 'MXN'
    }).format(amount || 0);
};

const getAccountMenuItems = (account) => {
    return [
        {
            label: 'Ver movimientos',
            icon: 'pi pi-list',
            command: () => handleViewTransactions(account)
        },
        {
            separator: true
        },
        {
            label: 'Editar cuenta',
            icon: 'pi pi-pencil',
            command: () => handleEditAccount(account)
        },
        {
            label: 'Eliminar cuenta',
            icon: 'pi pi-trash',
            command: () => handleDeleteAccount(account),
            class: 'text-red-500'
        }
    ];
};

const setAccountMenuRef = (el, accountId) => {
    if (el) {
        accountMenuRefs.value[accountId] = el;
    }
};

const toggleAccountMenu = (event, accountId) => {
    const menu = accountMenuRefs.value[accountId];
    if (menu) {
        menu.toggle(event);
    }
};

// MODAL HANDLERS
const handleNewAccount = () => {
    console.log('🆕 Nueva cuenta');
    
    modalEditMode.value = false;
    editingAccountId.value = null;
    showAccountModal.value = true;
};

const handleEditAccount = (account) => {
    console.log('✏️ Editar cuenta:', account);
    
    modalEditMode.value = true;
    editingAccountId.value = account.id;
    showAccountModal.value = true;
};

const handleModalClose = () => {
    console.log('❌ Cerrar modal');
    
    showAccountModal.value = false;
    modalEditMode.value = false;
    editingAccountId.value = null;
};

const handleAccountSubmit = async ({ data, isEdit, accountId, onSuccess, onError }) => {
    console.log('📤 Procesando envío de cuenta:', { data, isEdit, accountId });
    
    try {
        let result;

        if (isEdit && accountId) {
            // Actualizar cuenta existente
            console.log('📝 Actualizando cuenta:', accountId);
            result = await accountsStore.updateAccount(accountId, data, { toast });
        } else {
            // Crear nueva cuenta
            console.log('🆕 Creando nueva cuenta');
            result = await accountsStore.createAccount(data, { toast });
        }

        if (result) {
            console.log('✅ Operación exitosa:', result);
            onSuccess();
        } else {
            throw new Error('La operación no devolvió un resultado válido');
        }

    } catch (error) {
        console.error('💥 Error en handleAccountSubmit:', error);
        
        // Mostrar error específico
        toast.add({
            severity: 'error',
            summary: 'Error',
            detail: error.message || 'Error procesando la cuenta',
            life: 5000
        });
        
        onError(error);
    }
};

// ACCOUNT ACTIONS
const handleViewTransactions = (account) => {
    console.log('👁️ Ver movimientos de cuenta:', account);
    toast.add({
        severity: 'info',
        summary: 'Función pendiente',
        detail: 'Vista de movimientos próximamente',
        life: 3000
    });
};

const handleDeleteAccount = (account) => {
    console.log('🗑️ Eliminar cuenta:', account);
    
    confirm.require({
        message: `¿Estás seguro de eliminar la cuenta "${account.nombre}"?`,
        header: 'Confirmar Eliminación',
        icon: 'pi pi-exclamation-triangle',
        rejectClass: 'p-button-secondary p-button-outlined',
        rejectLabel: 'Cancelar',
        acceptLabel: 'Eliminar',
        acceptClass: 'p-button-danger',
        accept: async () => {
            try {
                await accountsStore.deleteAccount(account.id, { toast });
            } catch (error) {
                console.error('Error eliminando cuenta:', error);
            }
        }
    });
};

// Función para cargar datos
const loadData = async () => {
    try {
        console.log('🔄 Cargando datos...');
        
        // ✅ USAR FUNCIONES CON CACHÉ - NO FORZAR A MENOS QUE SEA NECESARIO
        await Promise.all([
            accountsStore.fetchBanks({ toast }),
            accountsStore.fetchAccountsWithDetails({ toast })
        ]);
        
        isInitialLoad.value = false;
        console.log('✅ Datos cargados exitosamente');
    } catch (error) {
        console.error('💥 Error cargando datos:', error);
        toast.add({
            severity: 'error',
            summary: 'Error al cargar',
            detail: 'No se pudieron cargar las cuentas',
            life: 5000
        });
    }
};

// ✅ NUEVA FUNCIÓN PARA REFRESCAR DATOS FORZADAMENTE
const refreshData = async () => {
    try {
        console.log('🔄 Refrescando datos...');
        
        // Usar las funciones de refresh que fuerzan la reconsulta
        await Promise.all([
            accountsStore.refreshBanks({ toast }),
            accountsStore.refreshAccounts({ toast })
        ]);
        
        toast.add({
            severity: 'success',
            summary: 'Actualizado',
            detail: 'Datos actualizados correctamente',
            life: 3000
        });
        
        console.log('✅ Datos refrescados exitosamente');
    } catch (error) {
        console.error('💥 Error refrescando datos:', error);
        toast.add({
            severity: 'error',
            summary: 'Error al actualizar',
            detail: 'No se pudieron actualizar los datos',
            life: 5000
        });
    }
};

// HOOKS
onMounted(() => {
    loadData();
});
</script>

<style scoped>
.account-card {
    transition: transform 0.2s ease-in-out;
}

.account-card:hover {
    transform: translateY(-2px);
}

.material-symbols-outlined {
    font-size: 20px;
}
</style>