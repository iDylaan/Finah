<template>
    <div class="flex flex-col gap-4">
        <!-- Cuenta -->
        <div class="flex flex-col gap-2">
            <label for="cuenta" class="font-semibold text-sm">Cuenta *</label>
            <Dropdown 
                id="cuenta"
                v-model="formData.cuenta_id" 
                :options="cuentas" 
                optionLabel="nombre"
                optionValue="id"
                placeholder="Selecciona una cuenta"
                :class="{ 'p-invalid': errors.cuenta_id }"
                class="w-full"
            >
                <template #value="slotProps">
                    <div v-if="slotProps.value" class="flex items-center gap-2">
                        <div class="w-8 h-8 rounded flex items-center justify-center text-white text-sm"
                            :style="{ backgroundColor: getAccountColor(getCuentaById(slotProps.value)) }">
                            <i v-if="getCuentaById(slotProps.value)?.banco?.libreria_icono === 'primevue'"
                                :class="getCuentaById(slotProps.value)?.banco?.nombre_icono"></i>
                            <span v-else-if="getCuentaById(slotProps.value)?.banco?.libreria_icono === 'material'"
                                class="material-symbols-rounded text-base">
                                {{ getCuentaById(slotProps.value)?.banco?.nombre_icono }}
                            </span>
                            <i v-else :class="getAccountIcon(getCuentaById(slotProps.value))"></i>
                        </div>
                        <span>{{ getCuentaById(slotProps.value)?.nombre }}</span>
                    </div>
                    <span v-else>{{ slotProps.placeholder }}</span>
                </template>
                <template #option="slotProps">
                    <div class="flex items-center gap-2">
                        <div class="w-8 h-8 rounded flex items-center justify-center text-white text-sm"
                            :style="{ backgroundColor: getAccountColor(slotProps.option) }">
                            <i v-if="slotProps.option.banco?.libreria_icono === 'primevue'"
                                :class="slotProps.option.banco.nombre_icono"></i>
                            <span v-else-if="slotProps.option.banco?.libreria_icono === 'material'"
                                class="material-symbols-rounded text-base">
                                {{ slotProps.option.banco.nombre_icono }}
                            </span>
                            <i v-else :class="getAccountIcon(slotProps.option)"></i>
                        </div>
                        <div class="flex-1">
                            <div class="font-medium">{{ slotProps.option.nombre }}</div>
                            <div class="text-xs text-surface-500">
                                {{ getAccountTypeLabel(slotProps.option.tipo) }}
                            </div>
                        </div>
                    </div>
                </template>
            </Dropdown>
            <small v-if="errors.cuenta_id" class="text-red-500">{{ errors.cuenta_id }}</small>
        </div>

        <!-- Categoría -->
        <div class="flex flex-col gap-2">
            <label for="categoria" class="font-semibold text-sm">Categoría *</label>
            <Dropdown 
                id="categoria"
                v-model="formData.categoria_id" 
                :options="categoryGroups" 
                optionLabel="nombre"
                optionValue="id"
                optionGroupLabel="nombre"
                optionGroupChildren="categories"
                placeholder="Selecciona una categoría"
                :class="{ 'p-invalid': errors.categoria_id }"
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
                    <div class="flex items-center gap-2 py-2">
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
            <small v-if="errors.categoria_id" class="text-red-500">{{ errors.categoria_id }}</small>
        </div>

        <!-- Nivel (Opcional) -->
        <div class="flex flex-col gap-2">
            <label for="nivel" class="font-semibold text-sm">Nivel de Prioridad</label>
            <Dropdown 
                id="nivel"
                v-model="formData.nivel_id" 
                :options="niveles" 
                optionLabel="nombre"
                optionValue="id"
                placeholder="Selecciona un nivel (opcional)"
                class="w-full"
                showClear
            >
                <template #value="slotProps">
                    <div v-if="slotProps.value" class="flex items-center gap-2">
                        <div class="w-4 h-4 rounded-full" 
                            :style="{ backgroundColor: getNivelById(slotProps.value)?.color }"></div>
                        <span>{{ getNivelById(slotProps.value)?.nombre }}</span>
                    </div>
                    <span v-else>{{ slotProps.placeholder }}</span>
                </template>
                <template #option="slotProps">
                    <div class="flex items-center gap-2">
                        <div class="w-4 h-4 rounded-full" 
                            :style="{ backgroundColor: slotProps.option.color }"></div>
                        <span>{{ slotProps.option.nombre }}</span>
                    </div>
                </template>
            </Dropdown>
        </div>

        <!-- Monto -->
        <div class="flex flex-col gap-2">
            <label for="monto" class="font-semibold text-sm">Monto *</label>
            <InputNumber
                id="monto"
                v-model="formData.monto"
                mode="currency"
                currency="MXN"
                locale="es-MX"
                :minFractionDigits="2"
                :maxFractionDigits="2"
                :class="{ 'p-invalid': errors.monto }"
                placeholder="$0.00"
                class="w-full"
            />
            <small v-if="errors.monto" class="text-red-500">{{ errors.monto }}</small>
        </div>

        <!-- Fecha -->
        <div class="flex flex-col gap-2">
            <label for="fecha" class="font-semibold text-sm">Fecha *</label>
            <DatePicker
                id="fecha"
                v-model="formData.fecha_ocurrencia"
                dateFormat="dd/mm/yy"
                :maxDate="new Date()"
                :class="{ 'p-invalid': errors.fecha_ocurrencia }"
                placeholder="Selecciona la fecha"
                class="w-full"
                showIcon
                iconDisplay="input"
            />
            <small v-if="errors.fecha_ocurrencia" class="text-red-500">{{ errors.fecha_ocurrencia }}</small>
        </div>

        <!-- Descripción -->
        <div class="flex flex-col gap-2">
            <label for="descripcion" class="font-semibold text-sm">Descripción</label>
            <Textarea
                id="descripcion"
                v-model="formData.descripcion"
                rows="3"
                placeholder="Agrega una descripción opcional..."
                class="w-full"
            />
        </div>
    </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue';

// Props
const props = defineProps({
    cuentas: {
        type: Array,
        required: true
    },
    categoryGroups: {
        type: Array,
        required: true
    },
    niveles: {
        type: Array,
        required: true
    }
});

// Emits
const emit = defineEmits(['update:modelValue', 'validate']);

// Form data
const formData = ref({
    cuenta_id: null,
    categoria_id: null,
    nivel_id: null,
    monto: null,
    fecha_ocurrencia: new Date(),
    descripcion: ''
});

// Errors
const errors = ref({});

// Helpers para obtener datos por ID
const getCuentaById = (id) => props.cuentas.find(c => c.id === id);
const getCategoriaById = (id) => {
    // Buscar en todos los grupos
    for (const group of props.categoryGroups) {
        const categoria = group.categories?.find(c => c.id === id);
        if (categoria) return categoria;
    }
    return null;
};
const getNivelById = (id) => props.niveles.find(n => n.id === id);

// Helper para obtener el color del grupo de una categoría
const getGroupColor = (categoria) => {
    if (!categoria) return '#6366f1';
    
    // Buscar el grupo al que pertenece la categoría
    const group = props.categoryGroups.find(g => g.id === categoria.grupo_id);
    return group?.color || '#6366f1';
};

// Helpers de cuentas (copiados de Accounts/index.vue)
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
    if (!account) return '#6366f1';
    if (account.banco?.color) return account.banco.color;

    const colors = {
        'cash': '#10b981',
        'bank': '#3b82f6',
        'debit_card': '#8b5cf6',
        'credit_card': '#f59e0b'
    };
    return colors[account.tipo] || '#6366f1';
};

const getAccountIcon = (account) => {
    if (!account) return 'pi pi-wallet';
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

// Validación
const validate = () => {
    errors.value = {};

    if (!formData.value.cuenta_id) {
        errors.value.cuenta_id = 'La cuenta es obligatoria';
    }
    if (!formData.value.categoria_id) {
        errors.value.categoria_id = 'La categoría es obligatoria';
    }
    if (!formData.value.monto || formData.value.monto <= 0) {
        errors.value.monto = 'El monto debe ser mayor a 0';
    }
    if (!formData.value.fecha_ocurrencia) {
        errors.value.fecha_ocurrencia = 'La fecha es obligatoria';
    }

    return Object.keys(errors.value).length === 0;
};

// Exponer datos y validación
defineExpose({
    formData,
    validate,
    reset: () => {
        formData.value = {
            cuenta_id: null,
            categoria_id: null,
            nivel_id: null,
            monto: null,
            fecha_ocurrencia: new Date(),
            descripcion: ''
        };
        errors.value = {};
    }
});

// Watch para emitir cambios
watch(formData, (newVal) => {
    emit('update:modelValue', newVal);
}, { deep: true });
</script>
