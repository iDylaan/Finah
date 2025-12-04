<template>
    <div class="flex flex-col gap-2">
        <label v-if="label" :for="inputId" class="font-semibold text-sm">
            {{ label }}
            <span v-if="required" class="text-red-500">*</span>
        </label>
        <Dropdown 
            :id="inputId"
            :modelValue="modelValue"
            @update:modelValue="$emit('update:modelValue', $event)"
            :options="categoryGroups" 
            optionLabel="nombre"
            optionValue="id"
            optionGroupLabel="nombre"
            optionGroupChildren="categories"
            :placeholder="placeholder"
            :class="{ 'p-invalid': invalid || error }"
            class="w-full"
            filter
            filterPlaceholder="Buscar categoría..."
        >
            <template #optiongroup="slotProps">
                <div class="flex items-center gap-2 font-semibold py-2">
                    <div class="w-8 h-8 rounded-lg flex items-center justify-center text-white"
                        :style="{ backgroundColor: slotProps.option.color || '#6366f1' }">
                        <i v-if="slotProps.option.biblioteca_iconos === 'primevue'"
                            :class="slotProps.option.nombre_icono" class="text-sm"></i>
                        <span v-else-if="slotProps.option.biblioteca_iconos === 'material'"
                            class="material-symbols-rounded text-base">
                            {{ slotProps.option.nombre_icono }}
                        </span>
                    </div>
                    <div class="flex-1">
                        <div>{{ slotProps.option.nombre }}</div>
                        <div v-if="slotProps.option.descripcion" class="text-xs font-normal text-surface-500 truncate">
                            {{ slotProps.option.descripcion }}
                        </div>
                    </div>
                </div>
            </template>
            <template #option="slotProps">
                <div class="flex items-center gap-2 py-2 pl-5">
                    <div class="w-8 h-8 rounded flex items-center justify-center"
                        :style="{ backgroundColor: getGroupColor(slotProps.option) + '20', color: getGroupColor(slotProps.option) }">
                        <i v-if="slotProps.option.biblioteca_iconos === 'primevue'"
                            :class="slotProps.option.nombre_icono" class="text-sm"></i>
                        <span v-else-if="slotProps.option.biblioteca_iconos === 'material'"
                            class="material-symbols-rounded text-base">
                            {{ slotProps.option.nombre_icono }}
                        </span>
                    </div>
                    <div class="flex-1 min-w-0">
                        <div class="font-medium">{{ slotProps.option.nombre }}</div>
                        <div v-if="slotProps.option.descripcion" 
                            class="text-xs text-surface-500 truncate max-w-[300px]"
                            :title="slotProps.option.descripcion">
                            {{ slotProps.option.descripcion }}
                        </div>
                    </div>
                </div>
            </template>
            <template #value="slotProps">
                <div v-if="slotProps.value" class="flex items-center gap-2">
                    <div class="w-8 h-8 rounded flex items-center justify-center"
                        :style="{ backgroundColor: getGroupColor(getCategoriaById(slotProps.value)) + '20', color: getGroupColor(getCategoriaById(slotProps.value)) }">
                        <i v-if="getCategoriaById(slotProps.value)?.biblioteca_iconos === 'primevue'"
                            :class="getCategoriaById(slotProps.value)?.nombre_icono" class="text-sm"></i>
                        <span v-else-if="getCategoriaById(slotProps.value)?.biblioteca_iconos === 'material'"
                            class="material-symbols-rounded text-base">
                            {{ getCategoriaById(slotProps.value)?.nombre_icono }}
                        </span>
                    </div>
                    <span>{{ getCategoriaById(slotProps.value)?.nombre }}</span>
                </div>
                <span v-else>{{ slotProps.placeholder }}</span>
            </template>
        </Dropdown>
        <small v-if="error" class="text-red-500">{{ error }}</small>
        <small v-else-if="hint" class="text-surface-500">{{ hint }}</small>
    </div>
</template>

<script setup>
import { computed } from 'vue';

const props = defineProps({
    modelValue: {
        type: [String, Number],
        default: null
    },
    categoryGroups: {
        type: Array,
        required: true
    },
    label: {
        type: String,
        default: 'Categoría'
    },
    placeholder: {
        type: String,
        default: 'Selecciona una categoría'
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
        default: 'categoria'
    }
});

defineEmits(['update:modelValue']);

// Helper para obtener categoría por ID
const getCategoriaById = (id) => {
    for (const group of props.categoryGroups) {
        const categoria = group.categories?.find(c => c.id === id);
        if (categoria) return categoria;
    }
    return null;
};

// Helper para obtener el color del grupo de una categoría
const getGroupColor = (categoria) => {
    if (!categoria) return '#6366f1';
    const group = props.categoryGroups.find(g => g.id === categoria.grupo_id);
    return group?.color || '#6366f1';
};
</script>
