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
                class="group rounded-xl overflow-hidden relative hover:shadow-lg hover:-translate-y-1 transition-all duration-300 border border-transparent hover:border-surface-300 dark:hover:border-surface-600"
                :style="{ backgroundColor: hexToRgba(getAccountColor(account), 0.1) }">

                <!-- Fondo con gradiente sutil -->
                <div class="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-300 pointer-events-none"
                    :style="{ background: `linear-gradient(135deg, ${hexToRgba(getAccountColor(account), 0.15)} 0%, ${hexToRgba(getAccountColor(account), 0.05)} 100%)` }">
                </div>

                <!-- Contenido -->
                <div class="relative">
                    <!-- Layout Desktop -->
                    <div class="hidden md:flex items-center gap-4 p-4 cursor-pointer" @click="handleEditAccount(account)">
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
                            <div class="flex items-center gap-2 text-xs text-surface-700 dark:text-surface-400">
                                <div class="flex items-center gap-2">
                                    <span>{{ getAccountTypeLabel(account.tipo) }}</span>
                                    <span v-if="account.banco">• {{ account.banco.nombre }}</span>
                                    <span v-if="account.metadatos?.last4">• ••{{ account.metadatos.last4 }}</span>
                                </div>
                                <!-- Fechas para tarjeta de crédito -->
                                <div v-if="account.tipo === 'credit_card'" class="flex items-center gap-3 text-xs text-surface-900 dark:text-surface-300">
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
                                <p class="text-xs text-surface-700 dark:text-surface-400">
                                    de {{ formatCurrency(account.limite_credito) }}
                                </p>
                            </div>
                            <div v-else>
                                <p class="text-lg font-bold text-surface-900 dark:text-surface-0">
                                    {{ formatCurrency(account.saldo) }}
                                </p>
                                <p class="text-xs text-surface-700 dark:text-surface-400">saldo actual</p>
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
                    <div class="md:hidden p-3 cursor-pointer" @click="handleEditAccount(account)">
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

                    <!-- Encabezado colapsable para detalles de tarjeta de crédito -->
                    <div 
                        v-if="account.tipo === 'credit_card'"
                        @click.stop="toggleCardExpansion(account.id)"
                        class=" bg-surface-100 dark:bg-surface-900 px-3 md:px-4 py-2.5 flex items-center justify-between cursor-pointer hover:bg-surface-50 dark:hover:bg-surface-800 transition-colors"
                    >
                        <span class="text-sm font-medium text-surface-700 dark:text-surface-300">Detalles</span>
                        <i :class="isCardExpanded(account.id) ? 'pi pi-chevron-up' : 'pi pi-chevron-down'" 
                           class="text-surface-600 dark:text-surface-400 text-xs transition-transform duration-200"></i>
                    </div>

                    <!-- Información detallada de tarjeta de crédito (colapsable) -->
                    <Transition
                        enter-active-class="transition-all duration-100 ease-out"
                        enter-from-class=" max-h-0"
                        enter-to-class=" max-h-[1000px]"
                        leave-active-class="transition-all duration-100 ease-in"
                        leave-from-class=" max-h-[1000px]"
                        leave-to-class=" max-h-0"
                    >
                        <div v-if="account.tipo === 'credit_card' && isCardExpanded(account.id)" 
                            class="bg-surface-100 dark:bg-surface-900 px-3 md:px-4 pb-3 md:pb-4 pt-3 overflow-hidden"
                            @click.stop>
                            <CreditCardInfo :card="account" @open-payment-modal="handleOpenPaymentModal(account.id)" />
                        </div>
                    </Transition>
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
            :is-loading="modalLoading" 
            @submit="handleAccountSubmit"
            @cancel="handleModalCancel"
            @close="handleModalCancel"
        />

        <!-- Modal de Transacciones -->
        <TransactionModal />

        <!-- Modal de Pago de Tarjeta -->
        <CreditCardPaymentModal 
            v-model:visible="showPaymentModal"
            :credit-card-id="selectedCardForPayment"
            @payment-registered="handlePaymentRegistered"
        />
    </PageLayout>
</template>

<script setup>
// IMPORTS
import { ref, onMounted, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import { useAccountsStore } from '@/stores/accounts.js';
import { useModalsStore } from '@/stores/ui-modals.js';
import PageLayout from '@/components/PageLayout.vue';
import AccountModal from './components/AccountModal.vue';
import TransactionModal from '@/views/modules/Transactions/components/TransactionModal.vue';
import CreditCardInfo from './components/CreditCardInfo.vue';
import CreditCardPaymentModal from './components/CreditCardPaymentModal.vue';
import { formatDate } from '@/lib/utils.js';

// STORES & COMPOSABLES
const router = useRouter();
const toast = useToast();
const confirm = useConfirm();
const accountsStore = useAccountsStore();
const modalsStore = useModalsStore();

// Estado del modal de pago de tarjeta
const showPaymentModal = ref(false);
const selectedCardForPayment = ref(null);

// VARIABLES
const isInitialLoad = ref(true);
const accounts = computed(() => accountsStore.accounts);
const accountMenuRefs = ref({});

// Estado de expansión de tarjetas de crédito
const expandedCards = ref({});

// MODAL STATE
const showAccountModal = ref(false);
const modalEditMode = ref(false);
const editingAccountId = ref(null);
const modalLoading = ref(false);

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

const getAccountMenuItems = (account) => {
    return [
        {
            label: 'Ver movimientos',
            icon: 'pi pi-list',
            command: () => handleViewTransactions(account)
        },
        {
            label: 'Realizar transferencia',
            icon: 'pi pi-arrow-right',
            command: () => handleTransferFromAccount(account)
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

// TOGGLE EXPANSION
const toggleCardExpansion = (accountId) => {
    expandedCards.value[accountId] = !expandedCards.value[accountId];
};

const isCardExpanded = (accountId) => {
    return expandedCards.value[accountId] || false;
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

    modalLoading.value = true;
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
    } finally {
        modalLoading.value = false;
    }
};

// ACCOUNT ACTIONS
const handleViewTransactions = (account) => {
    console.log('👁️ Ver movimientos de cuenta:', account);
    router.push(`/accounts/${account.id}/dashboard`);
};

const handleTransferFromAccount = (account) => {
    console.log('💸 Transferir desde cuenta:', account);
    modalsStore.openTransferenciaModal(account.id);
};

const handleOpenPaymentModal = (cardId) => {
    console.log('💳 Abrir modal de pago para tarjeta:', cardId);
    selectedCardForPayment.value = cardId;
    showPaymentModal.value = true;
};

const handlePaymentRegistered = () => {
    console.log('✅ Pago registrado exitosamente');
    // El modal ya refrescará las cuentas automáticamente
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