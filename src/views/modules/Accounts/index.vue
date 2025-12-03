<template>
    <PageLayout 
        title="Mis Cuentas" 
        description="Gestiona tus cuentas bancarias, tarjetas de crédito y efectivo"
    >
        <!-- Acciones del header -->
        <template #actions>
            <Button 
                icon="pi pi-refresh" 
                @click="refreshData" 
                :loading="accountsStore.loading" 
                severity="secondary" 
                outlined 
                size="small"
                v-tooltip.bottom="'Actualizar'"
            />
            <Button 
                icon="pi pi-plus" 
                @click="handleNewAccount" 
                :disabled="accountsStore.loading" 
                size="small" 
                label="Nueva Cuenta"
                class="mobile-icon-only"
            />
        </template>

        <!-- Loading State -->
        <div v-if="accountsStore.loading && accounts.length === 0" class="flex justify-center items-center py-12">
            <ProgressSpinner />
        </div>

        <!-- Content -->
        <div v-else-if="accounts.length > 0" class="grid grid-cols-1 gap-3 md:gap-4">
            <div v-for="account in accounts" :key="account.id"
                class="group cursor-pointer rounded-xl overflow-hidden relative hover:shadow-lg hover:-translate-y-1 transition-all duration-300 border border-transparent hover:border-surface-300 dark:hover:border-surface-600"
                :style="{ backgroundColor: hexToRgba(getAccountColor(account), 0.1) }"
                @click="handleEditAccount(account)">

                <!-- Fondo con gradiente sutil -->
                <div class="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                    :style="{ background: `linear-gradient(135deg, ${hexToRgba(getAccountColor(account), 0.15)} 0%, ${hexToRgba(getAccountColor(account), 0.05)} 100%)` }">
                </div>

                <!-- Contenido -->
                <div class="relative">
                    <!-- Layout Desktop -->
                    <div class="hidden md:flex items-center gap-4 p-4">
                        <!-- Icono de la cuenta/banco -->
                        <div class="flex-shrink-0 w-14 h-14 rounded-lg flex items-center justify-center"
                            :style="{ backgroundColor: hexToRgba(getAccountColor(account), 0.9) }">
                            <i v-if="account.banco?.libreria_icono === 'primevue'"
                                :class="[account.banco.nombre_icono, 'text-2xl text-white']"></i>
                            <span v-else-if="account.banco?.libreria_icono === 'material'"
                                class="material-symbols-rounded text-white text-2xl">
                                {{ account.banco.nombre_icono }}
                            </span>
                            <i v-else :class="getAccountIcon(account)" class="text-white text-2xl"></i>
                        </div>

                        <!-- Info de la cuenta -->
                        <div class="flex-1 min-w-0">
                            <h3 class="text-base font-semibold text-surface-900 dark:text-surface-100 truncate mb-0.5">
                                {{ account.nombre }}
                            </h3>
                            <div class="flex items-center gap-2 text-xs text-surface-500 dark:text-surface-400">
                                <div class="flex items-center gap-2">
                                    <span>{{ getAccountTypeLabel(account.tipo) }}</span>
                                    <span v-if="account.banco">• {{ account.banco.nombre }}</span>
                                    <span v-if="account.metadatos?.last4">• ••{{ account.metadatos.last4 }}</span>
                                </div>
                                <!-- Fechas para tarjeta de crédito -->
                                <div v-if="account.tipo === 'credit_card'" class="flex items-center gap-3 text-xs text-surface-600 dark:text-surface-400">
                                    <div v-if="account.proxima_fecha_corte" class="flex items-center gap-1">
                                        <i class="pi pi-calendar text-[10px]"></i>
                                        <span class="whitespace-nowrap">Corte: {{ formatDate(account.proxima_fecha_corte) }}</span>
                                    </div>
                                    <div v-if="account.proxima_fecha_pago" class="flex items-center gap-1">
                                        <i class="pi pi-calendar-plus text-[10px]"></i>
                                        <span class="whitespace-nowrap">Pago: {{ formatDate(account.proxima_fecha_pago) }}</span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Información de saldo/crédito (solo números) -->
                        <div class="text-right flex-shrink-0">
                            <div v-if="account.tipo === 'credit_card'">
                                <p class="text-lg font-bold text-surface-900 dark:text-surface-0">
                                    {{ formatCurrency(account.credito_disponible) }}
                                </p>
                                <p class="text-xs text-surface-500">
                                    de {{ formatCurrency(account.limite_credito) }}
                                </p>
                            </div>
                            <div v-else>
                                <p class="text-lg font-bold text-surface-900 dark:text-surface-0">
                                    {{ formatCurrency(account.saldo) }}
                                </p>
                                <p class="text-xs text-surface-500">saldo actual</p>
                            </div>
                        </div>

                        <!-- Menú de acciones -->
                        <div class="flex-shrink-0">
                            <button class="p-2 rounded-lg hover:bg-surface-100 dark:hover:bg-surface-700 transition-colors opacity-0 group-hover:opacity-100"
                                @click.stop="toggleAccountMenu($event, account.id)">
                                <i class="pi pi-ellipsis-v text-surface-600 dark:text-surface-400 text-sm"></i>
                            </button>

                            <Menu :ref="(el) => setAccountMenuRef(el, account.id)" :id="`account_menu_${account.id}`"
                                :model="getAccountMenuItems(account)" popup />
                        </div>
                    </div>

                    <!-- Layout Mobile -->
                    <div class="md:hidden p-3">
                        <div class="flex items-start gap-3 mb-2">
                            <!-- Icono -->
                            <div class="flex-shrink-0 w-11 h-11 rounded-lg flex items-center justify-center"
                                :style="{ backgroundColor: hexToRgba(getAccountColor(account), 0.9) }">
                                <i v-if="account.banco?.libreria_icono === 'primevue'"
                                    :class="[account.banco.nombre_icono, 'text-lg text-white']"></i>
                                <span v-else-if="account.banco?.libreria_icono === 'material'"
                                    class="material-symbols-rounded text-white text-lg">
                                    {{ account.banco.nombre_icono }}
                                </span>
                                <i v-else :class="getAccountIcon(account)" class="text-white text-lg"></i>
                            </div>

                            <!-- Nombre y tipo -->
                            <div class="flex-1 min-w-0">
                                <h3 class="text-sm font-semibold text-surface-900 dark:text-surface-100 truncate mb-0.5">
                                    {{ account.nombre }}
                                </h3>
                                <div class="flex items-center gap-1.5 text-[11px] text-surface-500 dark:text-surface-400">
                                    <span>{{ getAccountTypeLabel(account.tipo) }}</span>
                                    <span v-if="account.banco">• {{ account.banco.nombre }}</span>
                                </div>
                            </div>

                            <!-- Menú móvil -->
                            <button class="p-1.5 rounded-lg active:bg-surface-200 dark:active:bg-surface-700"
                                @click.stop="toggleAccountMenu($event, account.id)">
                                <i class="pi pi-ellipsis-v text-surface-600 dark:text-surface-400 text-sm"></i>
                            </button>
                        </div>

                        <!-- Saldo/Crédito -->
                        <div class="mb-2 pl-14">
                            <div v-if="account.tipo === 'credit_card'">
                                <div class="flex items-baseline gap-1.5">
                                    <p class="text-xl font-bold text-surface-900 dark:text-surface-0">
                                        {{ formatCurrency(account.credito_disponible) }}
                                    </p>
                                    <p class="text-[10px] text-surface-500">
                                        / {{ formatCurrency(account.limite_credito) }}
                                    </p>
                                </div>
                                <p class="text-[10px] text-surface-500 -mt-0.5">crédito disponible</p>
                            </div>
                            <div v-else>
                                <p class="text-xl font-bold text-surface-900 dark:text-surface-0">
                                    {{ formatCurrency(account.saldo) }}
                                </p>
                                <p class="text-[10px] text-surface-500 -mt-0.5">saldo actual</p>
                            </div>
                        </div>

                        <!-- Fechas para tarjeta de crédito -->
                        <div v-if="account.tipo === 'credit_card' && (account.proxima_fecha_corte || account.proxima_fecha_pago)" 
                            class="flex items-center gap-3 pl-14 text-[10px] text-surface-600 dark:text-surface-400">
                            <div v-if="account.proxima_fecha_corte" class="flex items-center gap-1">
                                <i class="pi pi-calendar text-[8px]"></i>
                                <span>Corte: {{ formatDate(account.proxima_fecha_corte) }}</span>
                            </div>
                            <div v-if="account.proxima_fecha_pago" class="flex items-center gap-1">
                                <i class="pi pi-calendar-plus text-[8px]"></i>
                                <span>Pago: {{ formatDate(account.proxima_fecha_pago) }}</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Empty State -->
        <div v-else class="flex items-center justify-center min-h-[200px] py-8 px-4">
            <div class="text-center max-w-md">
                <span class="material-symbols-outlined text-surface-300 dark:text-surface-600" style="font-size: 3.5rem">account_balance_wallet</span>
                <h3 class="text-base font-medium text-surface-700 dark:text-surface-300 mb-2">
                    No hay cuentas registradas
                </h3>
                <p class="text-sm text-surface-500 dark:text-surface-400 mb-4">
                    Registra tu primera cuenta bancaria, tarjeta o efectivo para comenzar
                </p>
                <Button label="Crear Primera Cuenta" icon="pi pi-plus" @click="handleNewAccount" size="small" />
            </div>
        </div>

        <!-- Modal de Cuenta -->
        <AccountModal 
            v-model:visible="showAccountModal"
            :is-edit="modalEditMode" 
            :edit-account-id="editingAccountId" 
            :accounts="accounts"
            :banks="accountsStore.banks" 
            :is-loading="accountsStore.loading" 
            @submit="handleAccountSubmit"
            @cancel="handleModalCancel"
            @close="handleModalCancel"
        />
    </PageLayout>
</template>

<script setup>
// IMPORTS
import { ref, onMounted, computed } from 'vue';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import { useAccountsStore } from '@/stores/accounts.js';
import PageLayout from '@/components/PageLayout.vue';
import AccountModal from './components/AccountModal.vue';

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

// FUNCTIONS - Helper para convertir hex a rgba con opacidad
const hexToRgba = (hex, opacity = 1) => {
    // Remover el # si existe
    hex = hex.replace('#', '');
    
    // Convertir hex de 3 dígitos a 6 dígitos
    if (hex.length === 3) {
        hex = hex.split('').map(char => char + char).join('');
    }
    
    // Extraer RGB
    const r = parseInt(hex.substring(0, 2), 16);
    const g = parseInt(hex.substring(2, 4), 16);
    const b = parseInt(hex.substring(4, 6), 16);
    
    return `rgba(${r}, ${g}, ${b}, ${opacity})`;
};

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

const formatDate = (dateString) => {
    if (!dateString) return '';
    
    let dateObj;
    if (typeof dateString === 'string') {
        // Si es un string YYYY-MM-DD, parsearlo correctamente en zona local
        const [year, month, day] = dateString.split('-').map(Number);
        dateObj = new Date(year, month - 1, day);
    } else {
        dateObj = new Date(dateString);
    }
    
    return dateObj.toLocaleDateString('es-MX', { 
        day: '2-digit', 
        month: 'short',
        timeZone: 'America/Mexico_City'
    });
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

const handleModalCancel = () => {
    showAccountModal.value = false;
    modalEditMode.value = false;
    editingAccountId.value = null;
};

const handleAccountSubmit = async ({ data, isEdit, accountId }) => {
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
            handleModalCancel(); // Cerrar el modal al completar exitosamente
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
        await Promise.all([
            accountsStore.fetchBanks({ toast }),
            accountsStore.fetchAccountsWithDetails({ toast })
        ]);

        isInitialLoad.value = false;
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

// Función para refrescar datos forzadamente
const refreshData = async () => {
    try {
        console.log('🔄 Refrescando datos...');

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

<style lang="scss" scoped>
// Estilos adicionales si son necesarios
</style>