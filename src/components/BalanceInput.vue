<template>
  <div class="balance-input-wrapper">
    <!-- Input visible que actúa como trigger para el modal -->
    <div class="p-inputgroup">
      <InputText
        :value="formattedValue"
        class="balance-display w-full text-right"
        readonly
        @click="showCalculator = true"
        :class="{'p-filled': modelValue > 0}"
      />
      <Button 
        type="button" 
        icon="pi pi-calculator" 
        @click="showCalculator = true" 
        class="p-button-secondary"
        aria-label="Calculadora"
      />
    </div>

    <!-- Modal de calculadora -->
    <Dialog 
      v-model:visible="showCalculator" 
      modal 
      :header="modalTitle"
      :style="{ width: '350px' }" 
      :dismissableMask="true"
      :closeOnEscape="true"
    >
      <div class="calculator-modal">
        <!-- Display para mostrar el valor actual y la expresión -->
        <div class="display-container mb-3">
          <div class="expression" v-if="showExpression">{{ currentExpression || '0' }}</div>
          <div class="value" :class="{ 'has-expression': showExpression && currentExpression }">
            {{ formattedValue }}
          </div>
        </div>

        <!-- Teclado de la calculadora -->
        <div class="calculator-keypad">
          <!-- Fila 1: Operaciones avanzadas -->
          <div class="calculator-row">
            <button 
              type="button" 
              class="calculator-btn operation" 
              @click="clear"
              title="Borrar todo"
            >
              C
            </button>
            <button 
              type="button" 
              class="calculator-btn operation" 
              @click="backspace"
              title="Borrar último dígito"
            >
              <i class="pi pi-delete-left"></i>
            </button>
            <button 
              type="button" 
              class="calculator-btn operation" 
              @click="appendOperator('%')"
              title="Porcentaje"
            >
              %
            </button>
            <button 
              type="button" 
              class="calculator-btn operation" 
              @click="appendOperator('/')"
              title="Dividir"
            >
              ÷
            </button>
          </div>

          <!-- Fila 2: 7-8-9 y multiplicación -->
          <div class="calculator-row">
            <button 
              type="button" 
              class="calculator-btn" 
              @click="appendDigit('7')"
            >
              7
            </button>
            <button 
              type="button" 
              class="calculator-btn" 
              @click="appendDigit('8')"
            >
              8
            </button>
            <button 
              type="button" 
              class="calculator-btn" 
              @click="appendDigit('9')"
            >
              9
            </button>
            <button 
              type="button" 
              class="calculator-btn operation" 
              @click="appendOperator('*')"
              title="Multiplicar"
            >
              ×
            </button>
          </div>

          <!-- Fila 3: 4-5-6 y resta -->
          <div class="calculator-row">
            <button 
              type="button" 
              class="calculator-btn" 
              @click="appendDigit('4')"
            >
              4
            </button>
            <button 
              type="button" 
              class="calculator-btn" 
              @click="appendDigit('5')"
            >
              5
            </button>
            <button 
              type="button" 
              class="calculator-btn" 
              @click="appendDigit('6')"
            >
              6
            </button>
            <button 
              type="button" 
              class="calculator-btn operation" 
              @click="appendOperator('-')"
              title="Restar"
            >
              −
            </button>
          </div>

          <!-- Fila 4: 1-2-3 y suma -->
          <div class="calculator-row">
            <button 
              type="button" 
              class="calculator-btn" 
              @click="appendDigit('1')"
            >
              1
            </button>
            <button 
              type="button" 
              class="calculator-btn" 
              @click="appendDigit('2')"
            >
              2
            </button>
            <button 
              type="button" 
              class="calculator-btn" 
              @click="appendDigit('3')"
            >
              3
            </button>
            <button 
              type="button" 
              class="calculator-btn operation" 
              @click="appendOperator('+')"
              title="Sumar"
            >
              +
            </button>
          </div>

          <!-- Fila 5: 0, punto decimal y evaluar -->
          <div class="calculator-row">
            <button 
              type="button" 
              class="calculator-btn" 
              @click="appendDigit('0')"
              style="flex: 2"
            >
              0
            </button>
            <button 
              type="button" 
              class="calculator-btn" 
              @click="appendDecimal"
              title="Punto decimal"
            >
              .
            </button>
            <button 
              type="button" 
              class="calculator-btn evaluate" 
              @click="evaluate"
              title="Calcular"
            >
              =
            </button>
          </div>
        </div>

        <!-- Botones de acción del modal -->
        <div class="flex justify-end gap-2 mt-4 pt-3 border-t border-surface-200 dark:border-surface-700">
          <Button 
            type="button" 
            label="Cancelar" 
            icon="pi pi-times" 
            @click="cancelCalculator" 
            class="p-button-secondary p-button-text"
          />
          <Button 
            type="button" 
            label="Aceptar" 
            icon="pi pi-check" 
            @click="acceptCalculator" 
            class="p-button-primary"
          />
        </div>
      </div>
    </Dialog>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import Dialog from 'primevue/dialog';
import Button from 'primevue/button';
import InputText from 'primevue/inputtext';

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
const currentExpression = ref('');
const isCalculating = ref(false);
const hasDecimal = ref(false);
const decimalDigits = ref(0);

// Formateo del valor como moneda
const formattedValue = computed(() => {
  const formatter = new Intl.NumberFormat('es-MX', {
    style: 'currency',
    currency: props.currency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  });
  
  return formatter.format(showCalculator.value ? tempValue.value : currentValue.value);
});

// Validar si un carácter es un operador
const isOperator = (char) => {
  return ['+', '-', '*', '/', '%'].includes(char);
};

// Validar si la expresión termina en operador
const endsWithOperator = () => {
  return currentExpression.value.length > 0 && 
         isOperator(currentExpression.value.slice(-1));
};

// Validar si ya se ha agregado un punto decimal en el número actual
const hasDecimalPoint = () => {
  // Buscar el último operador
  const lastOperatorIndex = Math.max(
    currentExpression.value.lastIndexOf('+'),
    currentExpression.value.lastIndexOf('-'),
    currentExpression.value.lastIndexOf('*'),
    currentExpression.value.lastIndexOf('/')
  );
  
  // Verificar si hay un punto después del último operador
  return currentExpression.value.slice(lastOperatorIndex + 1).includes('.');
};

// Inicializar el componente
onMounted(() => {
  if (props.modelValue) {
    currentValue.value = parseFloat(props.modelValue);
  }
});

// Métodos para la interacción con la calculadora
const appendDigit = (digit) => {
  // Si el valor es 0 y no hay punto decimal, reemplazarlo
  if (currentExpression.value === '0' && digit !== '0' && !hasDecimalPoint()) {
    currentExpression.value = digit;
  } else {
    // Limitar la longitud máxima
    if (currentExpression.value.replace(/[+\-*/%.]/g, '').length >= props.maxDigits) {
      return;
    }
    
    // Si estamos calculando, comenzar una nueva expresión
    if (!isCalculating.value) {
      currentExpression.value += digit;
    } else {
      currentExpression.value = digit;
      isCalculating.value = false;
    }
  }
  
  // Evaluar la expresión en tiempo real
  try {
    // eslint-disable-next-line no-eval
    let result = eval(currentExpression.value);
    
    // Asegurar que el resultado no sea negativo
    if (result >= 0) {
      tempValue.value = result;
    } else {
      // Si el resultado es negativo, volver al estado anterior
      currentExpression.value = currentExpression.value.slice(0, -1);
    }
  } catch (e) {
    // En caso de error, mantener el valor actual
    console.warn('Error evaluando expresión:', e);
  }
};

const appendOperator = (operator) => {
  // No permitir operadores si la expresión está vacía
  if (currentExpression.value === '') {
    if (operator === '-') {
      // Solo permitir '-' como primer carácter si el valor es 0
      if (tempValue.value === 0) {
        currentExpression.value = operator;
      }
    } else {
      // Para otros operadores, comenzar con el valor actual
      currentExpression.value = tempValue.value.toString() + operator;
    }
  } 
  // Si la expresión ya termina en operador, reemplazarlo
  else if (endsWithOperator()) {
    currentExpression.value = currentExpression.value.slice(0, -1) + operator;
  } 
  // Caso normal: añadir el operador
  else {
    currentExpression.value += operator;
  }
  
  isCalculating.value = false;
  hasDecimal.value = false;
  decimalDigits.value = 0;
};

const appendDecimal = () => {
  // No añadir punto decimal si ya hay uno en el número actual
  if (hasDecimalPoint()) {
    return;
  }
  
  // Si la expresión está vacía o termina en operador, añadir "0."
  if (currentExpression.value === '' || endsWithOperator()) {
    currentExpression.value += '0.';
  } else {
    currentExpression.value += '.';
  }
  
  hasDecimal.value = true;
};

const evaluate = () => {
  if (currentExpression.value === '') {
    return;
  }
  
  try {
    // Si termina en operador, quitar el operador
    if (endsWithOperator()) {
      currentExpression.value = currentExpression.value.slice(0, -1);
    }
    
    // eslint-disable-next-line no-eval
    let result = eval(currentExpression.value);
    
    // Asegurar que el resultado no sea negativo
    if (result < 0) {
      result = 0;
    }
    
    // Limitar a 2 decimales
    result = Math.round((result + Number.EPSILON) * 100) / 100;
    
    tempValue.value = result;
    currentExpression.value = result.toString();
    
    isCalculating.value = true;
  } catch (e) {
    console.error('Error evaluando expresión:', e);
  }
};

const clear = () => {
  tempValue.value = 0;
  currentExpression.value = '';
  isCalculating.value = false;
  hasDecimal.value = false;
  decimalDigits.value = 0;
};

const backspace = () => {
  if (currentExpression.value) {
    // Eliminar el último carácter
    const lastChar = currentExpression.value.slice(-1);
    currentExpression.value = currentExpression.value.slice(0, -1);
    
    // Si borramos un punto decimal
    if (lastChar === '.') {
      hasDecimal.value = false;
    }
    
    // Si la expresión queda vacía, restablecer a 0
    if (currentExpression.value === '') {
      tempValue.value = 0;
    } else {
      // Evaluar la nueva expresión
      try {
        // eslint-disable-next-line no-eval
        let result = eval(currentExpression.value);
        if (result >= 0) {
          tempValue.value = result;
        }
      } catch (e) {
        // En caso de error, mantener el valor actual
      }
    }
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

// Manejar la apertura del modal
watch(() => showCalculator.value, (isVisible) => {
  if (isVisible) {
    // Al abrir el modal, inicializar con el valor actual
    tempValue.value = currentValue.value;
    currentExpression.value = tempValue.value > 0 ? tempValue.value.toString() : '';
    isCalculating.value = false;
  }
});
</script>

<style scoped>
.balance-input-wrapper {
  width: 100%;
}

.balance-display {
  font-weight: 500;
  cursor: pointer;
}

.calculator-modal {
  width: 100%;
}

.display-container {
  padding: 16px;
  background-color: var(--surface-section, #f8f9fa);
  border-radius: 8px;
  text-align: right;
}

.expression {
  font-size: 0.875rem;
  color: var(--text-color-secondary, #6c757d);
  height: 1.2rem;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.value {
  font-size: 1.5rem;
  font-weight: bold;
  color: var(--text-color, #212529);
  padding: 4px 0;
}

.value.has-expression {
  color: var(--primary-color, #3B82F6);
}

.calculator-keypad {
  padding: 8px 0;
}

.calculator-row {
  display: flex;
  margin-bottom: 8px;
}

.calculator-row:last-child {
  margin-bottom: 0;
}

.calculator-btn {
  flex: 1;
  min-height: 48px;
  margin: 0 4px;
  border-radius: 4px;
  background-color: var(--surface-ground, #f8f9fa);
  color: var(--text-color, #212529);
  font-size: 1.25rem;
  font-weight: 500;
  border: none;
  cursor: pointer;
  transition: background-color 0.2s, transform 0.1s;
}

.calculator-btn:hover {
  background-color: var(--surface-hover, #e9ecef);
}

.calculator-btn:active {
  transform: scale(0.98);
}

.calculator-btn.operation {
  background-color: var(--surface-hover, #e9ecef);
  color: var(--primary-color, #3B82F6);
}

.calculator-btn.evaluate {
  background-color: var(--primary-color, #3B82F6);
  color: white;
}

.calculator-btn.evaluate:hover {
  background-color: var(--primary-600, #2563eb);
}

/* Responsive styles */
@media (max-width: 480px) {
  .calculator-btn {
    min-height: 40px;
    font-size: 1.1rem;
  }
  
  .value {
    font-size: 1.25rem;
  }
}
</style>