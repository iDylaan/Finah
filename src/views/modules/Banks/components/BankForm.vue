<template>
    <Dialog v-model:visible="isVisible" modal :header="dialogTitle" :style="{ width: '95vw', maxWidth: '32rem' }" 
        :breakpoints="{ '768px': '100vw' }" :contentStyle="{ maxHeight: 'calc(100vh - 120px)', overflowY: 'auto' }" 
        class="mobile-fullscreen-dialog">
        <div v-if="isLoadingData" class="flex justify-center py-8">
            <ProgressSpinner />
        </div>
        <div v-else class="space-y-4">
            <div>
                <label class="block text-sm font-medium mb-2">Nombre del banco</label>
                <InputText v-model.trim="bankForm.name" class="w-full" :disabled="isReadOnlyMode || isSubmitting"
                    :class="{ 'p-invalid': formErrors.name }" />
                <small v-if="formErrors.name" class="p-error block mt-1">{{ formErrors.name }}</small>
            </div>

            <div class="grid grid-cols-2 gap-4">
                <!-- Selector de color personalizado -->
                <div>
                    <label class="block text-sm font-medium mb-2">Color</label>
                    <CustomColorPicker v-model="bankForm.color" :disabled="isReadOnlyMode || isSubmitting" />
                </div>

                <!-- Selector de icono personalizado -->
                <div>
                    <label class="block text-sm font-medium mb-2">Ícono</label>
                    <IconPicker v-model="bankForm.iconName" v-model:iconType="bankForm.iconLibrary"
                        :color="bankForm.color" :disabled="isReadOnlyMode || isSubmitting" />
                </div>
            </div>

            <!-- Vista previa del banco -->
            <div class="mt-4">
                <label class="block text-sm font-medium mb-2">Vista previa</label>
                <div class="flex items-center gap-3 p-3 bg-surface-50 dark:bg-surface-800 rounded-lg">
                    <div class="w-12 h-12 flex items-center justify-center rounded-lg"
                        :style="{ backgroundColor: bankForm.color }">
                        <i v-if="bankForm.iconLibrary === 'primevue'"
                            :class="[bankForm.iconName, 'text-2xl text-white']"></i>
                        <span v-else-if="bankForm.iconLibrary === 'material'"
                            class="material-symbols-rounded text-white text-2xl">
                            {{ bankForm.iconName }}
                        </span>
                    </div>

                    <div class="flex-1">
                        <div class="font-medium">{{ bankForm.name || 'Nombre del banco' }}</div>
                        <div class="text-sm text-surface-600 dark:text-surface-400">
                            {{ bankForm.iconLibrary === 'primevue' ? 'PrimeVue' : 'Material' }} | {{ bankForm.color }}
                        </div>
                    </div>
                </div>
            </div>

            <!-- Vista de solo lectura para bancos públicos -->
            <div v-if="isPublicBank" class="mt-4 p-3 bg-blue-50 dark:bg-blue-900 rounded-lg">
                <div class="flex items-start gap-2">
                    <i class="pi pi-info-circle text-blue-500 dark:text-blue-300 mt-0.5"></i>
                    <div>
                        <p class="text-sm text-blue-800 dark:text-blue-200">
                            Este es un banco público del sistema y no puede ser modificado.
                        </p>
                    </div>
                </div>
            </div>
        </div>

        <template #footer>
            <div class="flex justify-end gap-2">
                <Button label="Cerrar" severity="secondary" outlined @click="handleClose"
                    :disabled="isSubmitting || isLoadingData" />

                <Button v-if="!isReadOnlyMode" :label="isEditMode ? 'Actualizar' : 'Crear'" severity="primary"
                    @click="submitBank" :loading="isSubmitting" :disabled="!isFormValid || isSubmitting" />
            </div>
        </template>
    </Dialog>
</template>

<script setup>
// IMPORTS
import { ref, computed, watch } from 'vue';
import { useBankStore } from '@/stores/banks.js';
import { useSessionStore } from '@/stores/session.js';
import { useToast } from 'primevue/usetoast';
import CustomColorPicker from '@/components/CustomColorPicker.vue';
import IconPicker from '@/components/IconPicker.vue';
import ICONS from '@/assets/constants/icon-providers.js';

// STORES
const bankStore = useBankStore();
const toast = useToast();
const sessionStore = useSessionStore();

// PROPS
const props = defineProps({
    visible: Boolean,
    isNew: Boolean,
    bankId: [String, Number],
    bank: Object,
    isLoading: Boolean,
});

// EMITS
const emit = defineEmits(['update:visible', 'close', 'success']);

// STATE
const isVisible = computed({
    get: () => props.visible,
    set: (value) => emit('update:visible', value)
});

// Formulario controlado por el componente
const bankForm = ref({
    name: '',
    color: '#4B5563',
    iconLibrary: ICONS.PRIMEVUE,
    iconName: 'pi pi-building'
});

const formErrors = ref({});
const isSubmitting = ref(false);
const isLoadingData = ref(false);
const loadedBankData = ref(null);

// COMPUTED
const dialogTitle = computed(() => {
    if (isReadOnlyMode.value) return 'Ver Banco';
    return isNewBank.value ? 'Crear Banco' : 'Editar Banco';
});

const isNewBank = computed(() => props.isNew);
const isEditMode = computed(() => !isNewBank.value);

const isPublicBank = computed(() => {
    // Asegurarnos de que es_publico se interprete correctamente como booleano
    return Boolean(loadedBankData.value?.es_publico);
});

const isReadOnlyMode = computed(() => {
    // Es un banco público o no es banco propio (del usuario actual)
    const readOnly = isPublicBank.value || (
        !isNewBank.value &&
        loadedBankData.value &&
        loadedBankData.value.usuario_id !== sessionStore.userId
    );

    return readOnly;
});

const isFormValid = computed(() => {
    return bankForm.value.name?.trim() &&
        bankForm.value.name.trim().length >= 2 &&
        bankForm.value.iconName?.trim() &&
        bankForm.value.color &&
        Object.keys(formErrors.value).length === 0;
});

// WATCHERS
// Observar cuando el modal se hace visible para inicializar correctamente
watch(() => props.visible, (newValue) => {
    if (newValue) {
        // NO inicializamos el formulario aquí para evitar limpiar datos ya cargados
        // La inicialización ahora se maneja en los watches específicos
    } else {
        // Limpiar después de cerrar
        resetFormState();
    }
});

// Watch para detectar cambios en los props que determinan qué banco mostrar
watch([() => props.isNew, () => props.bankId, () => props.bank, () => props.visible],
    async ([newIsNew, newBankId, newBank, newVisible]) => {
        if (newVisible) {
            // Prioridad: prop bank > bankId > isNew
            if (newIsNew) {
                // Caso 1: Nuevo banco
                setupNewBank();
            } else if (newBank) {
                // Caso 2: Banco pasado como prop
                loadBankFromProp(newBank);
            } else if (newBankId) {
                // Caso 3: ID de banco para cargar
                await loadBankData(newBankId);
            } else {
                // Caso fallback: no deberíamos llegar aquí
                console.warn('⚠️ Modal abierto sin condiciones claras. Configurando como nuevo banco.');
                setupNewBank();
            }
        }
    }, { immediate: true });

// METHODS
const resetFormState = () => {
    formErrors.value = {};
    isSubmitting.value = false;
    isLoadingData.value = false;
};

const initializeForm = (data = {}) => {
    // Inicializar con valores por defecto y luego sobreescribir con los datos proporcionados
    bankForm.value = {
        name: '',
        color: '#4B5563',
        iconLibrary: ICONS.PRIMEVUE,
        iconName: 'pi pi-building',
        ...data
    };

    resetFormState();
};

const setupNewBank = () => {
    console.log('🆕 Configurando nuevo banco');
    loadedBankData.value = null;
    initializeForm(); // Formulario vacío para nuevo banco
};

const loadBankFromProp = (bank) => {
    console.log('📥 Cargando banco desde props:', bank);

    if (!bank) {
        console.warn('⚠️ No se proporcionó datos de banco');
        setupNewBank();
        return;
    }

    // Guardar banco completo para acceder a propiedades como es_publico
    loadedBankData.value = { ...bank };

    // Normalizar el color para asegurarnos que tiene el formato correcto (#RRGGBB)
    const color = bank.color?.startsWith('#') ? bank.color : `#${bank.color || '4B5563'}`;

    // Inicializar formulario con datos del banco
    initializeForm({
        name: bank.nombre || '',
        color: color,
        iconLibrary: bank.biblioteca_iconos || ICONS.PRIMEVUE,
        iconName: bank.nombre_icono || 'pi pi-building'
    });

    console.log('📋 Formulario cargado:', bankForm.value);
};

const loadBankData = async (bankId) => {
    console.log('🔍 Cargando datos del banco:', bankId);

    if (!bankId) {
        console.warn('⚠️ No se proporcionó ID de banco');
        setupNewBank();
        return;
    }

    isLoadingData.value = true;

    try {
        // Buscar banco en los datos cargados
        const foundBank = bankStore.banks.find(b => b.id === bankId);

        if (!foundBank) {
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: 'No se encontró el banco solicitado',
                life: 3000
            });
            handleClose();
            return;
        }

        console.log('✅ Banco encontrado:', foundBank);

        // Guardar banco completo
        loadedBankData.value = { ...foundBank };

        // Normalizar el color para asegurarnos que tiene el formato correcto (#RRGGBB)
        const color = foundBank.color?.startsWith('#') ? foundBank.color : `#${foundBank.color || '4B5563'}`;

        // Inicializar formulario con datos del banco
        initializeForm({
            name: foundBank.nombre || '',
            color: color,
            iconLibrary: foundBank.biblioteca_iconos || ICONS.PRIMEVUE,
            iconName: foundBank.nombre_icono || 'pi pi-building'
        });

        console.log('📋 Formulario cargado:', bankForm.value);

    } catch (error) {
        console.error('❌ Error al cargar banco:', error);
        toast.add({
            severity: 'error',
            summary: 'Error',
            detail: 'Ocurrió un error al cargar el banco',
            life: 3000
        });
        handleClose();
    } finally {
        isLoadingData.value = false;
    }
};

const validateForm = () => {
    const errors = {};

    // Validar nombre
    if (!bankForm.value.name?.trim()) {
        errors.name = 'El nombre es obligatorio';
    } else if (bankForm.value.name.trim().length < 2) {
        errors.name = 'El nombre debe tener al menos 2 caracteres';
    }

    // Validar icono - ahora manejado por el componente IconPicker

    formErrors.value = errors;
    return Object.keys(errors).length === 0;
};

const submitBank = async () => {
    console.log('📝 Enviando formulario:', bankForm.value);
    
    // Verificación adicional para evitar modificar bancos públicos
    if (isPublicBank.value) {
        toast.add({
            severity: 'error',
            summary: 'Operación no permitida',
            detail: 'No puedes modificar un banco público del sistema',
            life: 3000
        });
        return;
    }
    
    if (!validateForm()) {
        console.warn('⚠️ Formulario inválido');
        return;
    }
    
    isSubmitting.value = true;
    
    try {
        // Preparar datos para enviar - aplicar trim al nombre
        const bankData = {
            name: bankForm.value.name.trim(),
            color: bankForm.value.color,
            iconLibrary: bankForm.value.iconLibrary,
            iconName: bankForm.value.iconName.trim()
        };
        
        console.log('Datos a enviar:', bankData);
        
        let result;
        
        if (isNewBank.value) {
            // Crear nuevo banco
            result = await bankStore.createBank(bankData, { toast });
        } else {
            // Actualizar banco existente
            result = await bankStore.updateBank(props.bankId, bankData, { toast });
        }
        
        if (result) {
            // Solo emitimos el evento, no añadimos un toast aquí
            emit('success', result);
        }
    } catch (error) {
        console.error('❌ Error al enviar banco:', error);
        // Este toast se mantiene porque es un manejo de error general
        toast.add({
            severity: 'error',
            summary: 'Error',
            detail: `Error al ${isNewBank.value ? 'crear' : 'actualizar'} el banco`,
            life: 3000
        });
    } finally {
        isSubmitting.value = false;
    }
};

const handleClose = () => {
    emit('close');
};
</script>

<style scoped>
.p-colorpicker {
    width: 100% !important;
}
</style>