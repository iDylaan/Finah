<template>
  <div class="w-full">
    <!-- Input visible que actúa como trigger para el modal -->
    <div class="flex w-full gap-2">
      <IconField class="flex-1">
        <InputIcon class="pi pi-dollar" />
        <InputText :value="formattedValue" class="w-full" readonly @click="showCalculator = true"
          placeholder="0.00" />
      </IconField>
      <Button type="button" icon="pi pi-calculator" @click="showCalculator = true" severity="secondary" outlined
        aria-label="Calculadora" />
    </div>

    <!-- Modal de calculadora -->
    <Dialog v-model:visible="showCalculator" modal :header="modalTitle"
      :style="{ width: '95vw', maxWidth: '25rem' }" 
      :breakpoints="{ '768px': '100vw' }"
      :contentStyle="{ maxHeight: 'calc(100vh - 120px)', overflowY: 'auto' }"
      class="mobile-fullscreen-dialog"
      :dismissableMask="true" :closeOnEscape="true">
      <div class="flex flex-col gap-4">
        <!-- Display avanzado para mostrar expresión, valor y preview -->
        <div class="bg-surface-50 dark:bg-surface-900 rounded-xl p-4 border border-surface-200 dark:border-surface-700">
          <!-- Expresión actual (historial de operaciones) - Siempre visible -->
          <div class="text-xs text-surface-500 dark:text-surface-400 min-h-[1rem] mb-2 text-right font-mono overflow-x-auto whitespace-nowrap">
            {{ displayExpression || '\u00A0' }}{{ currentNumber && currentNumber !== '0' && displayExpression ? formatDisplayValue(parseFloat(currentNumber)) : '' }}
          </div>

          <!-- Valor principal (número actual o resultado) -->
          <div class="text-3xl font-bold text-surface-900 dark:text-surface-0 text-right font-mono mb-1 truncate"
            :class="{ 'text-primary-600 dark:text-primary-400': displayExpression && !isCalculating }">
            {{ currentNumber && currentNumber !== '' ? formatDisplayValue(parseFloat(currentNumber)) : '0' }}
          </div>

          <!-- Previsualización del resultado -->
          <div v-if="showPreview && previewResult !== null"
            class="text-sm text-surface-400 dark:text-surface-500 min-h-[1.25rem] text-right font-mono italic">
            = {{ formatDisplayValue(previewResult) }}
          </div>
          <div v-else class="min-h-[1.25rem]"></div>
        </div>

        <!-- Teclado de la calculadora con Tailwind -->
        <div class="grid gap-2">
          <!-- Fila 1: C, Backspace, %, ÷ -->
          <div class="grid grid-cols-4 gap-2">
            <button type="button"
              class="h-14 rounded-lg bg-red-500 hover:bg-red-600 dark:bg-red-600 dark:hover:bg-red-700 text-white font-semibold transition-all duration-150 active:scale-95 shadow-sm"
              @click="clear" title="Borrar todo">
              C
            </button>
            <button type="button"
              class="h-14 rounded-lg bg-surface-100 hover:bg-surface-200 dark:bg-surface-700 dark:hover:bg-surface-600 text-surface-700 dark:text-surface-200 font-semibold transition-all duration-150 active:scale-95 shadow-sm"
              @click="backspace" title="Borrar último dígito">
              <i class="pi pi-delete-left text-lg"></i>
            </button>
            <button type="button"
              class="h-14 rounded-lg bg-primary-100 hover:bg-primary-200 dark:bg-primary-900/30 dark:hover:bg-primary-800/40 text-primary-700 dark:text-primary-300 font-semibold text-lg transition-all duration-150 active:scale-95 shadow-sm"
              @click="appendOperator('%')" title="Porcentaje">
              %
            </button>
            <button type="button"
              class="h-14 rounded-lg bg-primary-100 hover:bg-primary-200 dark:bg-primary-900/30 dark:hover:bg-primary-800/40 text-primary-700 dark:text-primary-300 font-semibold text-xl transition-all duration-150 active:scale-95 shadow-sm"
              @click="appendOperator('/')" title="Dividir">
              ÷
            </button>
          </div>

          <!-- Fila 2: 7, 8, 9, × -->
          <div class="grid grid-cols-4 gap-2">
            <button type="button"
              class="h-14 rounded-lg bg-surface-0 hover:bg-surface-100 dark:bg-surface-800 dark:hover:bg-surface-700 text-surface-900 dark:text-surface-0 font-semibold text-lg border border-surface-200 dark:border-surface-700 transition-all duration-150 active:scale-95 shadow-sm"
              @click="appendDigit('7')">
              7
            </button>
            <button type="button"
              class="h-14 rounded-lg bg-surface-0 hover:bg-surface-100 dark:bg-surface-800 dark:hover:bg-surface-700 text-surface-900 dark:text-surface-0 font-semibold text-lg border border-surface-200 dark:border-surface-700 transition-all duration-150 active:scale-95 shadow-sm"
              @click="appendDigit('8')">
              8
            </button>
            <button type="button"
              class="h-14 rounded-lg bg-surface-0 hover:bg-surface-100 dark:bg-surface-800 dark:hover:bg-surface-700 text-surface-900 dark:text-surface-0 font-semibold text-lg border border-surface-200 dark:border-surface-700 transition-all duration-150 active:scale-95 shadow-sm"
              @click="appendDigit('9')">
              9
            </button>
            <button type="button"
              class="h-14 rounded-lg bg-primary-100 hover:bg-primary-200 dark:bg-primary-900/30 dark:hover:bg-primary-800/40 text-primary-700 dark:text-primary-300 font-semibold text-xl transition-all duration-150 active:scale-95 shadow-sm"
              @click="appendOperator('*')" title="Multiplicar">
              ×
            </button>
          </div>

          <!-- Fila 3: 4, 5, 6, − -->
          <div class="grid grid-cols-4 gap-2">
            <button type="button"
              class="h-14 rounded-lg bg-surface-0 hover:bg-surface-100 dark:bg-surface-800 dark:hover:bg-surface-700 text-surface-900 dark:text-surface-0 font-semibold text-lg border border-surface-200 dark:border-surface-700 transition-all duration-150 active:scale-95 shadow-sm"
              @click="appendDigit('4')">
              4
            </button>
            <button type="button"
              class="h-14 rounded-lg bg-surface-0 hover:bg-surface-100 dark:bg-surface-800 dark:hover:bg-surface-700 text-surface-900 dark:text-surface-0 font-semibold text-lg border border-surface-200 dark:border-surface-700 transition-all duration-150 active:scale-95 shadow-sm"
              @click="appendDigit('5')">
              5
            </button>
            <button type="button"
              class="h-14 rounded-lg bg-surface-0 hover:bg-surface-100 dark:bg-surface-800 dark:hover:bg-surface-700 text-surface-900 dark:text-surface-0 font-semibold text-lg border border-surface-200 dark:border-surface-700 transition-all duration-150 active:scale-95 shadow-sm"
              @click="appendDigit('6')">
              6
            </button>
            <button type="button"
              class="h-14 rounded-lg bg-primary-100 hover:bg-primary-200 dark:bg-primary-900/30 dark:hover:bg-primary-800/40 text-primary-700 dark:text-primary-300 font-semibold text-xl transition-all duration-150 active:scale-95 shadow-sm"
              @click="appendOperator('-')" title="Restar">
              −
            </button>
          </div>

          <!-- Fila 4: 1, 2, 3, + -->
          <div class="grid grid-cols-4 gap-2">
            <button type="button"
              class="h-14 rounded-lg bg-surface-0 hover:bg-surface-100 dark:bg-surface-800 dark:hover:bg-surface-700 text-surface-900 dark:text-surface-0 font-semibold text-lg border border-surface-200 dark:border-surface-700 transition-all duration-150 active:scale-95 shadow-sm"
              @click="appendDigit('1')">
              1
            </button>
            <button type="button"
              class="h-14 rounded-lg bg-surface-0 hover:bg-surface-100 dark:bg-surface-800 dark:hover:bg-surface-700 text-surface-900 dark:text-surface-0 font-semibold text-lg border border-surface-200 dark:border-surface-700 transition-all duration-150 active:scale-95 shadow-sm"
              @click="appendDigit('2')">
              2
            </button>
            <button type="button"
              class="h-14 rounded-lg bg-surface-0 hover:bg-surface-100 dark:bg-surface-800 dark:hover:bg-surface-700 text-surface-900 dark:text-surface-0 font-semibold text-lg border border-surface-200 dark:border-surface-700 transition-all duration-150 active:scale-95 shadow-sm"
              @click="appendDigit('3')">
              3
            </button>
            <button type="button"
              class="h-14 rounded-lg bg-primary-100 hover:bg-primary-200 dark:bg-primary-900/30 dark:hover:bg-primary-800/40 text-primary-700 dark:text-primary-300 font-semibold text-xl transition-all duration-150 active:scale-95 shadow-sm"
              @click="appendOperator('+')" title="Sumar">
              +
            </button>
          </div>

          <!-- Fila 5: 0 (doble), punto decimal, = -->
          <div class="grid grid-cols-4 gap-2">
            <button type="button"
              class="col-span-2 h-14 rounded-lg bg-surface-0 hover:bg-surface-100 dark:bg-surface-800 dark:hover:bg-surface-700 text-surface-900 dark:text-surface-0 font-semibold text-lg border border-surface-200 dark:border-surface-700 transition-all duration-150 active:scale-95 shadow-sm"
              @click="appendDigit('0')">
              0
            </button>
            <button type="button"
              class="h-14 rounded-lg bg-surface-0 hover:bg-surface-100 dark:bg-surface-800 dark:hover:bg-surface-700 text-surface-900 dark:text-surface-0 font-semibold text-lg border border-surface-200 dark:border-surface-700 transition-all duration-150 active:scale-95 shadow-sm"
              @click="appendDecimal" title="Punto decimal">
              .
            </button>
            <button type="button"
              class="h-14 rounded-lg bg-green-500 hover:bg-green-600 dark:bg-green-600 dark:hover:bg-green-700 text-white font-semibold text-xl transition-all duration-150 active:scale-95 shadow-sm"
              @click="evaluate" title="Calcular">
              =
            </button>
          </div>
        </div>

        <!-- Botones de acción del modal -->
        <div class="flex justify-end gap-2 pt-2 border-t border-surface-200 dark:border-surface-700">
          <Button type="button" label="Cancelar" icon="pi pi-times" @click="cancelCalculator" severity="secondary"
            outlined size="small" />
          <Button type="button" label="Aceptar" icon="pi pi-check" @click="acceptCalculator" size="small" />
        </div>
      </div>
    </Dialog>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';

// Detección de móvil
const isMobile = ref(window.innerWidth < 768);

const handleResize = () => {
  isMobile.value = window.innerWidth < 768;
};

onMounted(() => {
  window.addEventListener('resize', handleResize);
});

onUnmounted(() => {
  window.removeEventListener('resize', handleResize);
});

// Props
const props = defineProps({
  modelValue: {
    type: [Number, String],
    default: 0
  },
  maxDigits: {
    type: Number,
    default: 12
  },
  showExpression: {
    type: Boolean,
    default: true
  },
  currency: {
    type: String,
    default: 'MXN'
  },
  modalTitle: {
    type: String,
    default: 'Calculadora'
  },
  label: {
    type: String,
    default: ''
  }
});

// Emits
const emit = defineEmits(['update:modelValue', 'change']);

// Estado
const showCalculator = ref(false);
const currentValue = ref(0);
const tempValue = ref(0);
const currentExpression = ref(''); // Expresión completa con operadores
const displayExpression = ref(''); // Expresión formateada para mostrar
const currentNumber = ref('0'); // Número actual que se está escribiendo
const isCalculating = ref(false);
const hasDecimal = ref(false);
const decimalDigits = ref(0);
const previewResult = ref(null);
const lastOperator = ref(''); // Último operador usado

// Computed para mostrar preview
const showPreview = computed(() => {
  return displayExpression.value &&
    !isCalculating.value &&
    previewResult.value !== null &&
    lastOperator.value !== '' &&
    currentNumber.value !== '';
});

// Función para formatear la expresión con símbolos matemáticos
const formatExpression = (expr) => {
  return expr
    .replace(/\*/g, ' × ')
    .replace(/\//g, ' ÷ ')
    .replace(/\+/g, ' + ')
    .replace(/-/g, ' − ')
    .replace(/%/g, ' % ');
};

// Función para formatear valores sin decimales innecesarios
const formatDisplayValue = (value) => {
  if (value === null || value === undefined) return '0';

  const numValue = parseFloat(value);

  // Si es un número entero, mostrarlo sin decimales
  if (Number.isInteger(numValue)) {
    return numValue.toLocaleString('es-MX');
  }

  // Si tiene decimales, mostrar hasta 2 decimales pero sin ceros innecesarios
  return numValue.toLocaleString('es-MX', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2
  });
};

// Formateo del valor como moneda para el input principal
const formattedValue = computed(() => {
  const value = showCalculator.value ? tempValue.value : currentValue.value;
  const numValue = parseFloat(value) || 0;

  // Formatear solo como número con separadores de miles, sin símbolo de moneda
  const formatter = new Intl.NumberFormat('es-MX', {
    minimumFractionDigits: Number.isInteger(numValue) ? 0 : 2,
    maximumFractionDigits: 2
  });

  return formatter.format(numValue);
});

// Función para calcular preview en tiempo real
const calculatePreview = () => {
  if (!currentExpression.value || isCalculating.value || lastOperator.value === '') {
    previewResult.value = null;
    return;
  }

  // Si no hay número actual, no mostrar preview
  if (currentNumber.value === '' || currentNumber.value === '0.') {
    previewResult.value = null;
    return;
  }

  try {
    // Construir la expresión completa para evaluar
    const fullExpression = currentExpression.value + currentNumber.value;
    
    // eslint-disable-next-line no-eval
    const result = eval(fullExpression);

    if (result >= 0 && !isNaN(result) && isFinite(result)) {
      // Redondear a 2 decimales
      previewResult.value = Math.round((result + Number.EPSILON) * 100) / 100;
    } else {
      previewResult.value = null;
    }
  } catch (e) {
    previewResult.value = null;
  }
};

// Validar si un carácter es un operador
const isOperator = (char) => {
  return ['+', '-', '*', '/', '%'].includes(char);
};

// Inicializar el componente
onMounted(() => {
  if (props.modelValue) {
    currentValue.value = parseFloat(props.modelValue);
  }
});

// Métodos para la interacción con la calculadora
const appendDigit = (digit) => {
  // Si estamos calculando (después de presionar =), comenzar nueva expresión
  if (isCalculating.value) {
    currentExpression.value = '';
    displayExpression.value = '';
    currentNumber.value = digit;
    lastOperator.value = '';
    isCalculating.value = false;
    tempValue.value = parseFloat(digit);
  } else {
    // Si el número actual es "0", reemplazarlo (excepto si hay punto decimal)
    if (currentNumber.value === '0' && !currentNumber.value.includes('.')) {
      currentNumber.value = digit;
    } else {
      // Limitar la longitud máxima
      if (currentNumber.value.replace(/\./g, '').length >= props.maxDigits) {
        return;
      }
      currentNumber.value += digit;
    }

    // Actualizar el valor temporal
    tempValue.value = parseFloat(currentNumber.value) || 0;
  }

  // Calcular preview
  calculatePreview();
};

const appendOperator = (operator) => {
  if (isCalculating.value) {
    // Si acabamos de calcular, usar el resultado como primer número
    currentExpression.value = tempValue.value.toString() + operator;
    displayExpression.value = formatDisplayValue(tempValue.value) + formatExpression(operator);
    currentNumber.value = '';
    lastOperator.value = operator;
    isCalculating.value = false;
  } else if (currentNumber.value === '' && currentExpression.value === '') {
    // Si no hay número ni expresión, no hacer nada (excepto para -)
    if (operator === '-' && tempValue.value === 0) {
      currentNumber.value = '-';
    }
    return;
  } else if (currentNumber.value === '') {
    // Si no hay número actual pero hay expresión, reemplazar el último operador
    if (lastOperator.value !== '') {
      currentExpression.value = currentExpression.value.slice(0, -1) + operator;
      displayExpression.value = displayExpression.value.substring(0, displayExpression.value.lastIndexOf(formatExpression(lastOperator.value))) + formatExpression(operator);
      lastOperator.value = operator;
    }
  } else {
    // Añadir el número actual y el operador a la expresión
    currentExpression.value += currentNumber.value + operator;
    displayExpression.value += formatDisplayValue(parseFloat(currentNumber.value)) + formatExpression(operator);
    
    // Evaluar la expresión actual para actualizar tempValue
    try {
      // eslint-disable-next-line no-eval
      let result = eval(currentExpression.value.slice(0, -1)); // Sin el último operador
      if (result >= 0) {
        tempValue.value = result;
      }
    } catch (e) {
      console.warn('Error evaluando expresión:', e);
    }
    
    currentNumber.value = '';
    lastOperator.value = operator;
  }

  hasDecimal.value = false;
  previewResult.value = null;
};

const appendDecimal = () => {
  // No añadir punto decimal si ya hay uno en el número actual
  if (currentNumber.value.includes('.')) {
    return;
  }

  if (isCalculating.value) {
    currentExpression.value = '';
    displayExpression.value = '';
    currentNumber.value = '0.';
    lastOperator.value = '';
    isCalculating.value = false;
  } else if (currentNumber.value === '') {
    currentNumber.value = '0.';
  } else {
    currentNumber.value += '.';
  }

  hasDecimal.value = true;
  tempValue.value = parseFloat(currentNumber.value) || 0;
  
  // Calcular preview
  calculatePreview();
};

const evaluate = () => {
  if (currentNumber.value === '' && currentExpression.value === '') {
    return;
  }

  try {
    let finalExpression = currentExpression.value;
    
    // Si hay un número actual, agregarlo a la expresión
    if (currentNumber.value !== '') {
      finalExpression += currentNumber.value;
    } else if (lastOperator.value !== '') {
      // Si termina en operador, quitarlo
      finalExpression = finalExpression.slice(0, -1);
    }

    // eslint-disable-next-line no-eval
    let result = eval(finalExpression);

    // Asegurar que el resultado no sea negativo
    if (result < 0) {
      result = 0;
    }

    // Limitar a 2 decimales
    result = Math.round((result + Number.EPSILON) * 100) / 100;

    tempValue.value = result;
    currentNumber.value = result.toString();
    currentExpression.value = '';
    displayExpression.value = '';
    lastOperator.value = '';
    isCalculating.value = true;
    previewResult.value = null;
  } catch (e) {
    console.error('Error evaluando expresión:', e);
  }
};

const clear = () => {
  tempValue.value = 0;
  currentExpression.value = '';
  displayExpression.value = '';
  currentNumber.value = '0';
  lastOperator.value = '';
  isCalculating.value = false;
  hasDecimal.value = false;
  decimalDigits.value = 0;
  previewResult.value = null;
};

const backspace = () => {
  if (isCalculating.value) {
    // Si acabamos de calcular, limpiar todo
    clear();
    return;
  }

  if (currentNumber.value && currentNumber.value !== '0') {
    // Eliminar el último carácter del número actual
    currentNumber.value = currentNumber.value.slice(0, -1);
    
    if (currentNumber.value === '' || currentNumber.value === '-') {
      currentNumber.value = '0';
      tempValue.value = 0;
    } else {
      tempValue.value = parseFloat(currentNumber.value) || 0;
    }

    // Calcular preview
    calculatePreview();
  } else if (lastOperator.value !== '') {
    // Si no hay número actual pero hay un operador, eliminar el operador
    currentExpression.value = currentExpression.value.slice(0, -1);
    displayExpression.value = displayExpression.value.substring(0, displayExpression.value.lastIndexOf(formatExpression(lastOperator.value)));
    
    // Encontrar el último número en la expresión
    const matches = currentExpression.value.match(/[\d.]+/g);
    if (matches && matches.length > 0) {
      currentNumber.value = matches[matches.length - 1];
      tempValue.value = parseFloat(currentNumber.value) || 0;
      currentExpression.value = currentExpression.value.slice(0, -currentNumber.value.length);
      displayExpression.value = displayExpression.value.substring(0, displayExpression.value.lastIndexOf(formatDisplayValue(tempValue.value)));
      
      // Encontrar el nuevo último operador
      const lastOp = currentExpression.value.slice(-1);
      lastOperator.value = isOperator(lastOp) ? lastOp : '';
    } else {
      currentNumber.value = '0';
      tempValue.value = 0;
    }
    
    lastOperator.value = '';
    previewResult.value = null;
  }
};

// Acciones del modal
const acceptCalculator = () => {
  currentValue.value = tempValue.value;
  emit('update:modelValue', currentValue.value);
  emit('change', currentValue.value);
  showCalculator.value = false;
};

const cancelCalculator = () => {
  showCalculator.value = false;
};

// Observar cambios en el modelValue
watch(() => props.modelValue, (newValue) => {
  currentValue.value = parseFloat(newValue) || 0;
});

</script>

<style scoped>
/* Móvil */
:deep(.calculator-modal-mobile.p-dialog) {
  max-width: 400px !important;
}

:deep(.calculator-modal-mobile .p-dialog-content) {
  padding: 1rem;
}

:deep(.calculator-modal-mobile .p-dialog-header) {
  padding: 1rem;
}

/* Estilos generales del modal */
:deep(.p-dialog-content) {
  padding: 1.25rem;
}

:deep(.p-dialog-header) {
  padding: 1.25rem;
  border-bottom: 1px solid var(--surface-border);
}
</style>