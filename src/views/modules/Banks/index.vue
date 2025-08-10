<template>
    <div class="banks-page">
        <div class="flex justify-between items-center">
            <h1 class="text-2xl font-bold">Bancos y entidades financieras</h1>

            <div class="flex gap-2">
                <Button icon="pi pi-refresh" outlined @click="refreshBanks" :loading="bankStore.loading"
                    class="p-button-sm" severity="secondary" />
                <Button label="Nuevo banco" icon="pi pi-plus" @click="openNewBankForm" severity="primary"
                    class="p-button-sm" />
            </div>
        </div>

        <!-- Loading Skeleton -->
        <div v-if="bankStore.loading && !bankStore.loaded" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            <div v-for="i in 6" :key="i"
                class="border border-surface-200 dark:border-surface-700 rounded-lg p-4 bg-surface-0 dark:bg-surface-800">
                <Skeleton height="3rem" class="mb-2" />
                <Skeleton height="1.5rem" class="mb-2" width="70%" />
                <Skeleton height="1.5rem" width="40%" />
            </div>
        </div>

        <!-- Error state -->
        <div v-else-if="bankStore.error" class="p-4 bg-red-50 dark:bg-red-900 rounded-lg mb-4">
            <div class="flex items-start gap-2">
                <i class="pi pi-exclamation-triangle text-red-500 dark:text-red-300 mt-0.5"></i>
                <div>
                    <p class="text-sm text-red-800 dark:text-red-200">
                        {{ bankStore.error }}
                    </p>
                    <Button label="Reintentar" icon="pi pi-refresh" @click="refreshBanks" severity="danger" text
                        size="small" class="mt-2" />
                </div>
            </div>
        </div>

        <div v-else>
            <!-- Mis bancos -->
            <div class="mb-6">
                <h2 class="text-lg font-medium mb-3">Mis bancos</h2>

                <!-- Empty state -->
                <div v-if="bankStore.userBanks.length === 0" class="p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
                    <p class="text-sm text-gray-600 dark:text-gray-300">
                        No has creado ningún banco personalizado todavía.
                    </p>
                    <Button label="Crear mi primer banco" icon="pi pi-plus" @click="openNewBankForm" text size="small"
                        class="mt-2" />
                </div>

                <!-- Banks grid -->
                <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    <div v-for="bank in bankStore.userBanks" :key="bank.id"
                        class="cursor-pointer border border-surface-200 dark:border-surface-700 rounded-lg overflow-hidden bg-surface-0 dark:bg-surface-800 relative hover:shadow-md transition-shadow duration-200"
                        @click="handleViewBank(bank)">

                        <!-- Header with background color -->
                        <div class="w-full h-16 flex items-center justify-center"
                            :style="{ backgroundColor: bank.color }">
                            <i v-if="bank.biblioteca_iconos === 'primevue'"
                                :class="[bank.nombre_icono, 'text-4xl text-white']"></i>
                            <span v-else-if="bank.biblioteca_iconos === 'material'"
                                class="material-symbols-rounded text-white text-2xl">
                                {{ bank.nombre_icono }}
                            </span>
                        </div>

                        <!-- Content -->
                        <div class="p-4">
                            <h3 class="text-lg font-medium text-surface-900 dark:text-surface-100 mb-2">
                                {{ bank.nombre }}
                            </h3>
                        </div>

                        <!-- Menú contextual -->
                        <button class="absolute right-2 top-2 p-2 rounded-full"
                            @click.stop="toggleBankMenu($event, bank.id)">
                            <i class="pi pi-ellipsis-v text-surface-600 dark:text-surface-400"></i>
                        </button>

                        <!-- Menú popup -->
                        <Menu :id="`bank-menu-${bank.id}`" :ref="el => setMenuRef(el, bank.id)"
                            :model="getBankMenuItems(bank)" popup />
                    </div>
                </div>
            </div>

            <!-- Bancos del sistema -->
            <div>
                <h2 class="text-lg font-medium mb-3">Bancos del sistema</h2>

                <!-- Empty state -->
                <div v-if="bankStore.publicBanks.length === 0" class="p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
                    <p class="text-sm text-gray-600 dark:text-gray-300">
                        No hay bancos del sistema disponibles.
                    </p>
                </div>

                <!-- Public banks grid -->
                <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    <div v-for="bank in bankStore.publicBanks" :key="bank.id"
                        class="cursor-pointer border border-surface-200 dark:border-surface-700 rounded-lg overflow-hidden bg-surface-0 dark:bg-surface-800 relative hover:shadow-md transition-shadow duration-200"
                        @click="handleViewBank(bank)">

                        <!-- Header with background color -->
                        <div class="w-full h-16 flex items-center justify-center"
                            :style="{ backgroundColor: bank.color }">
                            <i v-if="bank.biblioteca_iconos === 'primevue'"
                                :class="[bank.nombre_icono, 'text-4xl text-white']"></i>
                            <span v-else-if="bank.biblioteca_iconos === 'material'"
                                class="material-symbols-rounded text-white text-2xl">
                                {{ bank.nombre_icono }}
                            </span>
                        </div>

                        <!-- Content -->
                        <div class="p-4">
                            <div class="flex items-center gap-2">
                                <h3 class="text-lg font-medium text-surface-900 dark:text-surface-100">
                                    {{ bank.nombre }}
                                </h3>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Formulario modal para crear/editar bancos -->
        <BankForm v-model:visible="formVisible" :is-new="isNewBank" :bank-id="selectedBankId" :bank="selectedBank"
            @close="handleFormClose" @success="handleFormSuccess" />
    </div>
</template>

<script setup>
// IMPORTS
import { ref, onMounted, computed } from 'vue';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import { useBankStore } from '@/stores/banks.js';
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
.banks-page {
    padding: 1rem;
}

// Transición suave para hover
.bank-card {
    transition: transform 0.2s, box-shadow 0.2s;

    &:hover {
        transform: translateY(-2px);
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    }
}
</style>