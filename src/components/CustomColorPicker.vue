<template>
    <div>
        <div class="flex items-center justify-end flex-col gap-2 mt-2">
            <!-- ColorPicker de PrimeVue -->
            <div class="grid content-center">
                <ColorPicker v-model="internalColor" format="hex" :disabled="disabled"
                    @update:modelValue="handleColorPickerChange" />
            </div>

            <!-- Input de texto para el color hex -->
            <div class="flex-1">
                <InputGroup>
                    <InputGroupAddon>
                        #
                    </InputGroupAddon>
                    <InputText v-model="hexInput" @input="handleHexInput" @blur="validateAndNormalize"
                        @keyup.enter="validateAndNormalize" :disabled="disabled" placeholder="6366f1" maxlength="6"
                        class="rounded-l-none flex-1 font-mono text-sm w-full" :class="{ 'p-invalid': isInvalidHex }" />
                </InputGroup>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, computed, watch, nextTick } from 'vue';

// Props
const props = defineProps({
    modelValue: {
        type: String,
        default: '#6366f1'
    },
    label: {
        type: String,
        default: 'Color'
    },
    disabled: {
        type: Boolean,
        default: false
    }
});

// Emits
const emit = defineEmits(['update:modelValue']);

// Variables reactivas
const internalColor = ref(props.modelValue);
const hexInput = ref('');
const isInvalidHex = ref(false);

// Función para normalizar color
function normalizeColor(color) {
    if (!color) return '#6366f1';

    // Si ya tiene #, devolverlo tal como está
    if (color.startsWith('#')) {
        return color;
    }

    // Si es un color hex válido sin #, agregarlo
    if (/^[A-Fa-f0-9]{6}$/.test(color) || /^[A-Fa-f0-9]{3}$/.test(color)) {
        return `#${color}`;
    }

    // Si no es válido, devolver color por defecto
    console.warn('🎨 Color inválido recibido:', color);
    return '#6366f1';
}

// Función para extraer hex sin #
function extractHex(color) {
    if (!color) return '';
    return color.startsWith('#') ? color.slice(1) : color;
}

// Función para validar hex
function isValidHex(hex) {
    return /^[A-Fa-f0-9]{6}$/.test(hex) || /^[A-Fa-f0-9]{3}$/.test(hex);
}

// Computed para color seguro
const safeColor = computed(() => {
    const normalized = normalizeColor(internalColor.value);
    console.log('🎨 safeColor computed:', normalized);
    return normalized;
});

// Watchers
watch(() => props.modelValue, (newValue) => {
    if (newValue && newValue !== internalColor.value) {
        console.log('🎨 Props modelValue changed:', newValue);
        internalColor.value = normalizeColor(newValue);
        hexInput.value = extractHex(internalColor.value);
        isInvalidHex.value = false;
    }
}, { immediate: true });

watch(internalColor, (newColor) => {
    const normalized = normalizeColor(newColor);
    console.log('🎨 internalColor changed:', newColor, '→', normalized);

    if (normalized !== props.modelValue) {
        nextTick(() => {
            console.log('🎨 Emitiendo color:', normalized);
            emit('update:modelValue', normalized);
        });
    }
}, { immediate: false });

// Funciones
function handleColorPickerChange(newColor) {
    console.log('🎨 ColorPicker changed:', newColor);
    const normalized = normalizeColor(newColor);
    internalColor.value = normalized;
    hexInput.value = extractHex(normalized);
    isInvalidHex.value = false;
}

function handleHexInput(event) {
    const value = event.target.value;

    // Permitir solo caracteres hex
    const cleanValue = value.replace(/[^A-Fa-f0-9]/g, '');
    if (cleanValue !== value) {
        event.target.value = cleanValue;
        hexInput.value = cleanValue;
        return;
    }

    console.log('🎨 Hex input:', cleanValue);

    // Validar en tiempo real
    if (cleanValue.length === 0) {
        isInvalidHex.value = false;
    } else if (cleanValue.length === 3 || cleanValue.length === 6) {
        if (isValidHex(cleanValue)) {
            isInvalidHex.value = false;
            const newColor = `#${cleanValue}`;
            console.log('🎨 Actualizando color desde input:', newColor);
            internalColor.value = newColor;
        } else {
            isInvalidHex.value = true;
        }
    } else if (cleanValue.length > 6) {
        // Truncar a 6 caracteres
        const truncated = cleanValue.slice(0, 6);
        event.target.value = truncated;
        hexInput.value = truncated;
        if (isValidHex(truncated)) {
            isInvalidHex.value = false;
            internalColor.value = `#${truncated}`;
        }
    } else {
        // Longitud entre 1-2 o 4-5 caracteres
        isInvalidHex.value = cleanValue.length > 0;
    }
}

function validateAndNormalize() {
    const value = hexInput.value;

    if (!value) {
        // Si está vacío, mantener el color actual
        hexInput.value = extractHex(internalColor.value);
        isInvalidHex.value = false;
        return;
    }

    if (isValidHex(value)) {
        // Si es válido, normalizarlo
        let normalizedHex = value.toLowerCase();

        // Expandir colores cortos (ej: f00 -> ff0000)
        if (normalizedHex.length === 3) {
            normalizedHex = normalizedHex.split('').map(c => c + c).join('');
        }

        internalColor.value = `#${normalizedHex}`;
        hexInput.value = normalizedHex;
        isInvalidHex.value = false;
        console.log('🎨 Color normalizado:', `#${normalizedHex}`);
    } else {
        // Si no es válido, revertir al último valor válido
        hexInput.value = extractHex(internalColor.value);
        isInvalidHex.value = false;
        console.log('🎨 Revirtiendo a color válido:', internalColor.value);
    }
}

// Inicializar
const initialColor = normalizeColor(props.modelValue);
internalColor.value = initialColor;
hexInput.value = extractHex(initialColor);
console.log('🎨 Inicializando ColorPicker:', initialColor);
</script>

<style scoped>
.color-picker-button {
    width: 48px !important;
    height: 48px !important;
}

.color-picker-container {
    min-width: 200px;
}

/* Mejorar el aspecto del input hex */
.font-mono {
    font-family: 'Courier New', Courier, monospace;
}

/* Animación suave para el preview */
.color-picker-container .w-12.h-12 {
    transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}

.color-picker-container .w-12.h-12:hover {
    transform: scale(1.05);
}
</style>