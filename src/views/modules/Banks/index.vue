<template>
    <PageLayout title="Entidades Financieras"
        description="Gestiona tus bancos y entidades financieras para organizar tus cuentas">
        <!-- Acciones del header -->
        <template #actions>
            <Button icon="pi pi-refresh" @click="refreshBanks" :loading="bankStore.loading" severity="secondary"
                outlined size="small" v-tooltip.bottom="'Actualizar'" />
            <Button icon="pi pi-plus" @click="openNewBankForm" size="small" label="Nuevo Banco"
                class="mobile-icon-only" />
        </template>

        <!-- Contenido principal -->
        <div v-if="bankStore.loading && !bankStore.loaded" class="flex justify-center items-center py-12">
            <ProgressSpinner />
        </div>

        <!-- Error state -->
        <div v-else-if="bankStore.error"
            class="p-4 bg-red-50 dark:bg-red-900/20 rounded-lg border border-red-200 dark:border-red-800 mb-4">
            <div class="flex items-start gap-3">
                <i class="pi pi-exclamation-triangle text-red-600 dark:text-red-400 text-xl mt-0.5"></i>
                <div class="flex-1">
                    <p class="text-sm font-medium text-red-800 dark:text-red-200 mb-2">
                        {{ bankStore.error }}
                    </p>
                    <Button label="Reintentar" icon="pi pi-refresh" @click="refreshBanks" severity="danger" outlined
                        size="small" />
                </div>
            </div>
        </div>

        <div v-else>
            <!-- Mis bancos -->
            <div class="mb-8">
                <h2 class="text-lg font-semibold text-surface-900 dark:text-surface-0 mb-4">Mis bancos</h2>

                <!-- Empty state -->
                <div v-if="bankStore.userBanks.length === 0"
                    class="flex items-center justify-center min-h-[200px] py-8 px-4">
                    <div class="text-center max-w-md">
                        <i class="pi pi-building text-5xl text-surface-300 dark:text-surface-600 mb-4"></i>
                        <h3 class="text-base font-medium text-surface-700 dark:text-surface-300 mb-2">No tienes bancos
                            personalizados</h3>
                        <p class="text-sm text-surface-500 dark:text-surface-400 mb-4">
                            Crea tu primer banco personalizado para gestionar tus cuentas.
                        </p>
                        <Button label="Crear mi primer banco" icon="pi pi-plus" @click="openNewBankForm" size="small" />
                    </div>
                </div>

                <!-- Banks grid -->
                <div v-else class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                    <div v-for="bank in bankStore.userBanks" :key="bank.id"
                        class="group cursor-pointer rounded-xl overflow-hidden relative hover:shadow-lg hover:-translate-y-1 transition-all duration-300 border border-transparent hover:border-surface-300 dark:hover:border-surface-600"
                        :style="{ backgroundColor: hexToRgba(bank.color, 0.1) }" @click="handleViewBank(bank)">

                        <!-- Fondo con gradiente sutil -->
                        <div class="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                            :style="{ background: `linear-gradient(135deg, ${hexToRgba(bank.color, 0.15)} 0%, ${hexToRgba(bank.color, 0.05)} 100%)` }">
                        </div>

                        <!-- Contenido -->
                        <div class="relative">
                            <!-- Icon section -->
                            <div class="flex items-center gap-4 p-0">
                                <div class="flex-shrink-0 w-14 h-14 rounded-l-lg flex items-center justify-center"
                                    :style="{ backgroundColor: hexToRgba(bank.color, 0.9) }">
                                    <i v-if="bank.biblioteca_iconos === 'primevue'"
                                        :class="[bank.nombre_icono, 'text-2xl text-white']"></i>
                                    <span v-else-if="bank.biblioteca_iconos === 'material'"
                                        class="material-symbols-rounded text-white text-2xl">
                                        {{ bank.nombre_icono }}
                                    </span>
                                </div>

                                <div class="flex-1 min-w-0">
                                    <h3
                                        class="text-base font-semibold text-surface-900 dark:text-surface-100 truncate mb-0.5">
                                        {{ bank.nombre }}
                                    </h3>
                                </div>

                                <!-- Menú contextual -->
                                <button
                                    class="flex-shrink-0 p-2 rounded-lg hover:bg-surface-100 dark:hover:bg-surface-700 transition-colors opacity-0 group-hover:opacity-100 mr-3"
                                    @click.stop="toggleBankMenu($event, bank.id)">
                                    <i class="pi pi-ellipsis-v text-surface-600 dark:text-surface-400 text-sm"></i>
                                </button>
                            </div>
                        </div>

                        <!-- Menú popup -->
                        <Menu :id="`bank-menu-${bank.id}`" :ref="el => setMenuRef(el, bank.id)"
                            :model="getBankMenuItems(bank)" popup />
                    </div>
                </div>
            </div>

            <!-- Bancos del sistema -->
            <div>
                <h2 class="text-lg font-semibold text-surface-900 dark:text-surface-0 mb-4">Bancos del sistema</h2>

                <!-- Empty state -->
                <div v-if="bankStore.publicBanks.length === 0"
                    class="flex items-center justify-center min-h-[200px] py-8 px-4">
                    <div class="text-center max-w-md">
                        <i class="pi pi-info-circle text-5xl text-surface-300 dark:text-surface-600 mb-4"></i>
                        <p class="text-sm text-surface-600 dark:text-surface-400">
                            No hay bancos del sistema disponibles.
                        </p>
                    </div>
                </div>

                <!-- Public banks grid -->
                <div v-else class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                    <div v-for="bank in bankStore.publicBanks" :key="bank.id"
                        class="group cursor-pointer rounded-xl overflow-hidden relative hover:shadow-lg hover:-translate-y-1 transition-all duration-300 border border-transparent hover:border-surface-300 dark:hover:border-surface-600"
                        :style="{ backgroundColor: hexToRgba(bank.color, 0.1) }" @click="handleViewBank(bank)">

                        <!-- Fondo con gradiente sutil -->
                        <div class="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                            :style="{ background: `linear-gradient(135deg, ${hexToRgba(bank.color, 0.15)} 0%, ${hexToRgba(bank.color, 0.05)} 100%)` }">
                        </div>

                        <!-- Contenido -->
                        <div class="relative">
                            <!-- Icon section -->
                            <div class="flex items-center gap-4 p-0">
                                <div class="flex-shrink-0 w-14 h-14 rounded-l-lg flex items-center justify-center"
                                    :style="{ backgroundColor: hexToRgba(bank.color, 0.9) }">
                                    <i v-if="bank.biblioteca_iconos === 'primevue'"
                                        :class="[bank.nombre_icono, 'text-2xl text-white']"></i>
                                    <span v-else-if="bank.biblioteca_iconos === 'material'"
                                        class="material-symbols-rounded text-white text-2xl">
                                        {{ bank.nombre_icono }}
                                    </span>
                                </div>

                                <div class="flex min-w-0">
                                    <h3
                                        class="text-base font-semibold text-surface-900 dark:text-surface-100 truncate mb-0.5">
                                        {{ bank.nombre }}
                                    </h3>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Formulario modal para crear/editar bancos -->
        <BankForm v-model:visible="formVisible" :is-new="isNewBank" :bank-id="selectedBankId" :bank="selectedBank"
            @close="handleFormClose" @success="handleFormSuccess" />
    </PageLayout>
</template>

<script setup>
// IMPORTS
import { ref, onMounted, computed } from 'vue';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import { useBankStore } from '@/stores/banks.js';
import PageLayout from '@/components/PageLayout.vue';
import BankForm from './components/BankForm.vue';

// HOOKS
const toast = useToast();
const confirm = useConfirm();
const bankStore = useBankStore();

// STATE
const formVisible = ref(false);
const isNewBank = ref(true);
const selectedBankId = ref(null);
const selectedBank = ref(null);
const menuRefs = ref({});

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

// MOUNTED
onMounted(async () => {
    if (!bankStore.loaded) {
        await loadBanks();
    }
});

// METHODS
const loadBanks = async () => {
    try {
        await bankStore.fetchBanks();
    } catch (error) {
        console.error('Error al cargar bancos:', error);
    }
};

const refreshBanks = async () => {
    try {
        // Usamos refreshBanks que fuerza la reconsulta
        await bankStore.refreshBanks();
        toast.add({
            severity: 'success',
            summary: 'Actualizado',
            detail: 'Lista de bancos actualizada',
            life: 3000
        });
    } catch (error) {
        console.error('Error al actualizar bancos:', error);
        toast.add({
            severity: 'error',
            summary: 'Error',
            detail: 'No se pudieron actualizar los bancos',
            life: 3000
        });
    }
};

const openNewBankForm = () => {
    isNewBank.value = true;
    selectedBankId.value = null;
    selectedBank.value = null;
    formVisible.value = true;
};

const handleEditBank = (bank) => {
    isNewBank.value = false;
    selectedBankId.value = bank.id;
    selectedBank.value = bank;
    formVisible.value = true;
};

const handleViewBank = (bank) => {
    isNewBank.value = false;
    selectedBankId.value = bank.id;
    selectedBank.value = bank;
    formVisible.value = true;
};

const handleDeleteBank = (bank) => {
    confirm.require({
        message: `¿Estás seguro de que deseas eliminar el banco "${bank.nombre}"? Esta acción no se puede deshacer.`,
        header: 'Confirmar eliminación',
        icon: 'pi pi-exclamation-triangle',
        acceptLabel: 'Eliminar',
        acceptClass: 'p-button-danger',
        rejectLabel: 'Cancelar',
        rejectClass: 'p-button-secondary',
        acceptIcon: 'pi pi-trash',
        rejectIcon: 'pi pi-times',
        accept: () => {
            // Evitar llamar a deleteBank dos veces
            bankStore.deleteBank(bank.id, { toast })
                .then(success => {
                    if (success) {
                        // No agregamos un toast aquí, ya que el store ya lo hace
                        console.log(`Banco "${bank.nombre}" eliminado correctamente`);
                    }
                })
                .catch(error => {
                    console.error('Error al eliminar banco:', error);
                });
        }
    });
};

const handleFormClose = () => {
    formVisible.value = false;
    // Limpiar después de cerrar
    setTimeout(() => {
        selectedBankId.value = null;
        selectedBank.value = null;
    }, 300);
};

const handleFormSuccess = (bank) => {
    formVisible.value = false;
    toast.add({
        severity: 'success',
        summary: isNewBank.value ? 'Banco creado' : 'Banco actualizado',
        detail: `El banco "${bank.nombre}" ha sido ${isNewBank.value ? 'creado' : 'actualizado'} correctamente`,
        life: 3000
    });
};

// MENÚ CONTEXTUAL
const getBankMenuItems = (bank) => {
    return [
        {
            label: 'Editar',
            icon: 'pi pi-pencil',
            command: () => handleEditBank(bank)
        },
        {
            separator: true
        },
        {
            label: 'Eliminar',
            icon: 'pi pi-trash',
            class: 'text-red-600 dark:text-red-400',
            command: () => handleDeleteBank(bank)
        }
    ];
};

const setMenuRef = (el, bankId) => {
    if (el) {
        menuRefs.value[bankId] = el;
    }
};

const toggleBankMenu = (event, bankId) => {
    event.stopPropagation();
    if (menuRefs.value[bankId]) {
        menuRefs.value[bankId].toggle(event);
    }
};
</script>

<style lang="scss" scoped>
// Estilos adicionales si son necesarios</style>