<template>
    <div class="flex flex-col gap-2">
        <label v-if="label" :for="inputId" class="font-semibold text-sm">
            {{ label }}
            <span v-if="required" class="text-red-500">*</span>
        </label>
        <div class="flex gap-2">
            <Select 
                :id="inputId"
                :modelValue="modelValue"
                @update:modelValue="handleSelection"
                :options="levelsStore.levels" 
                optionLabel="nombre"
                optionValue="id"
                :placeholder="placeholder"
                :class="{ 'p-invalid': invalid || error }"
                class="flex-1"
                :disabled="disabled"
            >
                <template #option="slotProps">
                    <div class="flex items-center gap-2 py-2">
                        <div class="w-8 h-8 rounded flex items-center justify-center text-white shrink-0"
                            :style="{ backgroundColor: slotProps.option.color }">
                            <i v-if="slotProps.option.biblioteca_iconos === 'primevue'"
                                :class="slotProps.option.nombre_icono" class="text-sm"></i>
                            <span v-else-if="slotProps.option.biblioteca_iconos === 'material'"
                                class="material-symbols-rounded text-base">
                                {{ slotProps.option.nombre_icono }}
                            </span>
                        </div>
                        <div class="flex-1">
                            <div class="font-medium">{{ slotProps.option.nombre }}</div>
                            <div v-if="slotProps.option.descripcion" 
                                class="text-xs text-surface-500 truncate">
                                {{ slotProps.option.descripcion }}
                            </div>
                        </div>
                        <Tag :value="`Nivel ${slotProps.option.jerarquia}`" severity="info" class="text-xs" />
                    </div>
                </template>
                <template #value="slotProps">
                    <div v-if="slotProps.value" class="flex items-center gap-2">
                        <div class="w-8 h-8 rounded flex items-center justify-center text-white shrink-0"
                            :style="{ backgroundColor: getLevelById(slotProps.value)?.color }">
                            <i v-if="getLevelById(slotProps.value)?.biblioteca_iconos === 'primevue'"
                                :class="getLevelById(slotProps.value)?.nombre_icono" class="text-sm"></i>
                            <span v-else-if="getLevelById(slotProps.value)?.biblioteca_iconos === 'material'"
                                class="material-symbols-rounded text-base">
                                {{ getLevelById(slotProps.value)?.nombre_icono }}
                            </span>
                        </div>
                        <span>{{ getLevelById(slotProps.value)?.nombre }}</span>
                    </div>
                    <span v-else>{{ slotProps.placeholder }}</span>
                </template>
            </Select>
            <Button 
                icon="pi pi-refresh"
                severity="secondary"
                outlined
                :loading="levelsStore.loading"
                @click="handleRefresh"
                v-tooltip.top="'Actualizar niveles'"
                class="shrink-0"
            />
        </div>
        <small v-if="error" class="text-red-500">{{ error }}</small>
        <small v-else-if="hint" class="text-surface-500">{{ hint }}</small>
    </div>
</template>

<script setup>
import { useToast } from 'primevue/usetoast';
import { useLevelStore } from '@/stores/levels';

const toast = useToast();
const levelsStore = useLevelStore();

const props = defineProps({
    modelValue: {
        type: [String, Number],
        default: null
    },
    label: {
        type: String,
        default: 'Nivel de prioridad'
    },
    placeholder: {
        type: String,
        default: 'Selecciona un nivel'
    },
    required: {
        type: Boolean,
        default: false
    },
    invalid: {
        type: Boolean,
        default: false
    },
    error: {
        type: String,
        default: ''
    },
    hint: {
        type: String,
        default: ''
    },
    inputId: {
        type: String,
        default: 'nivel'
    },
    disabled: {
        type: Boolean,
        default: false
    }
});

const emit = defineEmits(['update:modelValue']);

// Handler para la selección
const handleSelection = (value) => {
    emit('update:modelValue', value);
};

// Helper para obtener nivel por ID
const getLevelById = (id) => {
    return levelsStore.levels.find(l => l.id === id);
};

// Handler para refrescar niveles
const handleRefresh = async () => {
    try {
        await levelsStore.fetchLevels({ toast, force: true });
        toast.add({
            severity: 'success',
            summary: 'Niveles actualizados',
            detail: 'La lista de niveles se ha actualizado correctamente',
            life: 3000
        });
    } catch (error) {
        console.error('Error refrescando niveles:', error);
    }
};
</script>
