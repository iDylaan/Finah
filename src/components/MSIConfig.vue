<script setup>
import { ref, computed, watch } from 'vue'
import { useRecurringTransactionsStore } from '@/stores/recurring-transactions'
import { useToast } from 'primevue/usetoast'
import { formatDate } from '@/lib/utils'

const props = defineProps({
  visible: {
    type: Boolean,
    default: false
  },
  creditCard: {
    type: Object,
    required: true
  },
  categoryId: {
    type: String,
    default: null
  },
  initialAmount: {
    type: Number,
    default: null
  },
  initialDescription: {
    type: String,
    default: null
  }
})

const emit = defineEmits(['update:visible', 'msi-created'])

const toast = useToast()
const recurringStore = useRecurringTransactionsStore()

// Estado del formulario
const nombre = ref('')
const descripcion = ref('')
const montoTotal = ref(null)
const numeroMeses = ref(3)
const mesesPersonalizados = ref(null)
const mesesYaPagados = ref(0)
const mostrarOpcionesAvanzadas = ref(false)
const tipoMonto = ref('automatico') // 'automatico', 'manual', 'redondeado'
const montoPorCuota = ref(null)
const tipRedondeo = ref('arriba') // 'arriba', 'abajo', 'cercano'

// Opciones de meses comunes para MSI
const opcionesMeses = [
  { label: '3 meses', value: 3 },
  { label: '6 meses', value: 6 },
  { label: '9 meses', value: 9 },
  { label: '12 meses', value: 12 },
  { label: '18 meses', value: 18 },
  { label: '24 meses', value: 24 },
  { label: '36 meses', value: 36 },
  { label: 'Personalizado', value: 'personalizado' }
]

// Cálculos automáticos
const montoPorMes = computed(() => {
  const mesesFinal = numeroMeses.value === 'personalizado' ? mesesPersonalizados.value : numeroMeses.value
  
  if (!montoTotal.value || !mesesFinal) return 0
  
  if (tipoMonto.value === 'manual' && montoPorCuota.value) {
    return parseFloat(montoPorCuota.value)
  }
  
  const montoCalculado = montoTotal.value / mesesFinal
  
  if (tipoMonto.value === 'redondeado') {
    if (tipoRedondeo.value === 'arriba') {
      return Math.ceil(montoCalculado)
    } else if (tipoRedondeo.value === 'abajo') {
      return Math.floor(montoCalculado)
    } else {
      return Math.round(montoCalculado)
    }
  }
  
  return montoCalculado.toFixed(2)
})

const mesesRestantes = computed(() => {
  const mesesFinal = numeroMeses.value === 'personalizado' ? mesesPersonalizados.value : numeroMeses.value
  if (!mesesFinal) return 0
  return mesesFinal - mesesYaPagados.value
})

const totalAPagar = computed(() => {
  if (!montoPorMes.value || !mesesRestantes.value) return '0.00'
  const total = montoPorMes.value * mesesRestantes.value
  return total.toFixed(2)
})

const diferenciaMonto = computed(() => {
  if (tipoMonto.value === 'automatico') return 0
  const totalRealCalculado = montoTotal.value || 0
  const totalConCuotas = parseFloat(montoPorMes.value || 0) * numeroMeses.value
  return (totalConCuotas - totalRealCalculado).toFixed(2)
})

const proximaFechaCorte = computed(() => {
  if (!props.creditCard?.proxima_fecha_corte) return 'No configurada'
  return formatDate(props.creditCard.proxima_fecha_corte, 'largo')
})

// Validaciones
const errors = ref({})

const validate = () => {
  errors.value = {}
  
  if (!nombre.value.trim()) {
    errors.value.nombre = 'El nombre es requerido'
  }
  
  if (!montoTotal.value || montoTotal.value <= 0) {
    errors.value.montoTotal = 'El monto total debe ser mayor a 0'
  }
  
  if (!numeroMeses.value || (numeroMeses.value !== 'personalizado' && numeroMeses.value < 1)) {
    errors.value.numeroMeses = 'Selecciona el número de meses'
  }
  
  if (numeroMeses.value === 'personalizado') {
    if (!mesesPersonalizados.value || mesesPersonalizados.value < 1) {
      errors.value.mesesPersonalizados = 'Ingresa un número de meses válido'
    }
  }
  
  const mesesActual = numeroMeses.value === 'personalizado' ? mesesPersonalizados.value : numeroMeses.value
  if (mesesYaPagados.value < 0 || mesesYaPagados.value >= mesesActual) {
    errors.value.mesesYaPagados = 'Los meses pagados deben ser menores al total'
  }
  
  if (!props.categoryId) {
    errors.value.categoria = 'Debes seleccionar una categoría'
  }
  
  return Object.keys(errors.value).length === 0
}

// Limpiar formulario
const resetForm = () => {
  nombre.value = ''
  descripcion.value = ''
  montoTotal.value = null
  numeroMeses.value = 3
  mesesYaPagados.value = 0
  mostrarOpcionesAvanzadas.value = false
  tipoMonto.value = 'automatico'
  montoPorCuota.value = null
  tipoRedondeo.value = 'arriba'
  errors.value = {}
}

// Crear MSI
const loading = ref(false)

const handleSubmit = async () => {
  if (!validate()) return
  
  loading.value = true
  
  try {
    // Usar meses personalizados si está seleccionado, sino usar el valor del dropdown
    const mesesFinal = numeroMeses.value === 'personalizado' 
      ? parseInt(mesesPersonalizados.value) 
      : parseInt(numeroMeses.value)
    
    const msiData = {
      cuenta_id: props.creditCard.id,
      categoria_id: props.categoryId,
      nombre: nombre.value.trim(),
      descripcion: descripcion.value.trim() || null,
      monto_total: parseFloat(montoTotal.value),
      numero_meses: mesesFinal,
      meses_ya_pagados: parseInt(mesesYaPagados.value)  // Corregido: meses_ya_pagados
    }

    // Agregar monto personalizado si no es automático
    if (tipoMonto.value !== 'automatico') {
      msiData.monto_por_mes = parseFloat(montoPorMes.value)
    }
    
    await recurringStore.createMSI(msiData, { toast })
    
    emit('msi-created')
    emit('update:visible', false)
    resetForm()
  } catch (error) {
    console.error('Error al crear MSI:', error)
  } finally {
    loading.value = false
  }
}

// Watchers para limpiar errores
watch(() => nombre.value, () => delete errors.value.nombre)
watch(() => montoTotal.value, () => delete errors.value.montoTotal)
watch(() => numeroMeses.value, () => delete errors.value.numeroMeses)
watch(() => mesesYaPagados.value, () => delete errors.value.mesesYaPagados)

// Inicializar con datos de transacción si existen
watch(() => props.visible, (newVal) => {
  if (newVal) {
    // Si hay valores iniciales (viene de una transacción), usarlos
    if (props.initialAmount) {
      montoTotal.value = props.initialAmount
    }
    if (props.initialDescription) {
      nombre.value = props.initialDescription
      descripcion.value = 'Pago diferido convertido desde transacción'
    }
  } else {
    setTimeout(resetForm, 300) // Delay para animación
  }
})
</script>

<template>
  <Dialog
    :visible="visible"
    @update:visible="$emit('update:visible', $event)"
    modal
    header="Diferir Pago a Meses"
    :style="{ width: '42rem' }"
    :breakpoints="{ '768px': '100vw' }"
    class="mobile-fullscreen-dialog"
    :contentStyle="{ maxHeight: 'calc(100vh - 120px)', overflowY: 'auto' }"
  >
    <form @submit.prevent="handleSubmit" class="flex flex-col gap-4">
      
      <!-- Información de la tarjeta -->
      <div class="p-3 bg-surface-50 dark:bg-surface-800 rounded-lg border border-surface-200 dark:border-surface-700">
        <div class="flex items-center gap-2 mb-2">
          <i class="pi pi-credit-card text-primary"></i>
          <span class="font-semibold">{{ creditCard.nombre }}</span>
        </div>
        <div class="text-sm text-surface-600 dark:text-surface-400">
          <p>Día de corte: {{ creditCard.dia_corte }}</p>
          <p>Próximo corte: {{ proximaFechaCorte }}</p>
        </div>
      </div>

      <!-- Nombre del pago diferido -->
      <div class="flex flex-col gap-2">
        <label for="nombre-msi" class="font-medium">
          Nombre de la compra <span class="text-red-500">*</span>
        </label>
        <InputText
          id="nombre-msi"
          v-model="nombre"
          placeholder="Ej: iPhone 15 Pro, Laptop Dell, TV Samsung"
          :invalid="!!errors.nombre"
          autofocus
        />
        <small v-if="errors.nombre" class="text-red-500">{{ errors.nombre }}</small>
      </div>

      <!-- Descripción (opcional) -->
      <div class="flex flex-col gap-2">
        <label for="descripcion-msi" class="font-medium">Descripción (opcional)</label>
        <Textarea
          id="descripcion-msi"
          v-model="descripcion"
          rows="2"
          placeholder="Detalles adicionales de la compra..."
        />
      </div>

      <!-- Monto total -->
      <div class="flex flex-col gap-2">
        <label for="monto-total" class="font-medium">
          Monto total <span class="text-red-500">*</span>
        </label>
        <InputNumber
          id="monto-total"
          v-model="montoTotal"
          mode="currency"
          currency="MXN"
          locale="es-MX"
          :min="0"
          :invalid="!!errors.montoTotal"
          placeholder="$0.00"
        />
        <small v-if="errors.montoTotal" class="text-red-500">{{ errors.montoTotal }}</small>
      </div>

      <!-- Número de meses -->
      <div class="flex flex-col gap-2">
        <label for="numero-meses" class="font-medium">
          Plazo <span class="text-red-500">*</span>
        </label>
        <Select
          id="numero-meses"
          v-model="numeroMeses"
          :options="opcionesMeses"
          optionLabel="label"
          optionValue="value"
          placeholder="Selecciona el plazo"
          :invalid="!!errors.numeroMeses"
        />
        <small v-if="errors.numeroMeses" class="text-red-500">{{ errors.numeroMeses }}</small>
      </div>

      <!-- Input para meses personalizados -->
      <div v-if="numeroMeses === 'personalizado'" class="flex flex-col gap-2">
        <label for="meses-personalizados" class="font-medium">
          Especifica el número de meses <span class="text-red-500">*</span>
        </label>
        <InputNumber
          id="meses-personalizados"
          v-model="mesesPersonalizados"
          :min="1"
          :max="60"
          placeholder="Ej: 15"
          :invalid="!!errors.mesesPersonalizados"
          showButtons
          buttonLayout="horizontal"
        >
          <template #incrementbuttonicon>
            <span class="pi pi-plus" />
          </template>
          <template #decrementbuttonicon>
            <span class="pi pi-minus" />
          </template>
        </InputNumber>
        <small v-if="errors.mesesPersonalizados" class="text-red-500">{{ errors.mesesPersonalizados }}</small>
      </div>

      <!-- Meses ya pagados (para MSI en progreso) -->
      <div class="flex flex-col gap-2">
        <label for="meses-pagados" class="font-medium">
          ¿Cuántos meses ya pagaste? (opcional)
        </label>
        <InputNumber
          id="meses-pagados"
          v-model="mesesYaPagados"
          :min="0"
          :max="numeroMeses - 1"
          :invalid="!!errors.mesesYaPagados"
          showButtons
          buttonLayout="horizontal"
          :step="1"
        >
          <template #incrementbuttonicon>
            <span class="pi pi-plus" />
          </template>
          <template #decrementbuttonicon>
            <span class="pi pi-minus" />
          </template>
        </InputNumber>
        <small v-if="errors.mesesYaPagados" class="text-red-500">{{ errors.mesesYaPagados }}</small>
        <small class="text-surface-600 dark:text-surface-400">
          Útil si ya empezaste a pagar este MSI y quieres registrar los meses restantes
        </small>
      </div>

      <!-- Opciones Avanzadas -->
      <div class="flex flex-col gap-3">
        <Button
          :label="mostrarOpcionesAvanzadas ? 'Ocultar opciones avanzadas' : 'Mostrar opciones avanzadas'"
          :icon="mostrarOpcionesAvanzadas ? 'pi pi-chevron-up' : 'pi pi-chevron-down'"
          severity="secondary"
          text
          size="small"
          @click="mostrarOpcionesAvanzadas = !mostrarOpcionesAvanzadas"
        />

        <div v-if="mostrarOpcionesAvanzadas" class="flex flex-col gap-3 p-3 bg-surface-50 dark:bg-surface-800 rounded-lg border border-surface-200 dark:border-surface-700">
          <h4 class="font-semibold text-sm">Ajustar monto de cuotas</h4>
          
          <!-- Tipo de cálculo de monto -->
          <div class="flex flex-col gap-2">
            <label class="font-medium text-sm">¿Cómo calcular el monto mensual?</label>
            
            <div class="flex flex-col gap-2">
              <div class="flex items-center">
                <RadioButton
                  inputId="tipo-automatico"
                  name="tipoMonto"
                  value="automatico"
                  v-model="tipoMonto"
                />
                <label for="tipo-automatico" class="ml-2 cursor-pointer">
                  <span class="font-medium">Automático</span>
                  <span class="text-xs text-surface-600 dark:text-surface-400 block">
                    División exacta: {{ montoTotal ? `$${(montoTotal / numeroMeses).toFixed(2)}` : '$0.00' }}
                  </span>
                </label>
              </div>

              <div class="flex items-center">
                <RadioButton
                  inputId="tipo-redondeado"
                  name="tipoMonto"
                  value="redondeado"
                  v-model="tipoMonto"
                />
                <label for="tipo-redondeado" class="ml-2 cursor-pointer flex-1">
                  <span class="font-medium">Redondeado</span>
                  <span class="text-xs text-surface-600 dark:text-surface-400 block">
                    Redondea automáticamente cada cuota
                  </span>
                </label>
              </div>

              <!-- Opciones de redondeo -->
              <div v-if="tipoMonto === 'redondeado'" class="ml-7 flex flex-col gap-2">
                <Select
                  v-model="tipoRedondeo"
                  :options="[
                    { label: 'Redondear hacia arriba (ej: 2090.94 → 2091)', value: 'arriba' },
                    { label: 'Redondear hacia abajo (ej: 2090.94 → 2090)', value: 'abajo' },
                    { label: 'Redondear al más cercano (ej: 2090.94 → 2091)', value: 'cercano' }
                  ]"
                  optionLabel="label"
                  optionValue="value"
                  placeholder="Tipo de redondeo"
                  class="w-full"
                />
              </div>

              <div class="flex items-center">
                <RadioButton
                  inputId="tipo-manual"
                  name="tipoMonto"
                  value="manual"
                  v-model="tipoMonto"
                />
                <label for="tipo-manual" class="ml-2 cursor-pointer">
                  <span class="font-medium">Manual</span>
                  <span class="text-xs text-surface-600 dark:text-surface-400 block">
                    Especifica el monto exacto que cobra el banco
                  </span>
                </label>
              </div>

              <!-- Input manual -->
              <div v-if="tipoMonto === 'manual'" class="ml-7">
                <InputNumber
                  v-model="montoPorCuota"
                  mode="currency"
                  currency="MXN"
                  locale="es-MX"
                  :min="0"
                  placeholder="Monto que cobra el banco por mes"
                  class="w-full"
                />
              </div>
            </div>
          </div>

          <!-- Advertencia de diferencia -->
          <Message v-if="diferenciaMonto != 0 && tipoMonto !== 'automatico'" :severity="parseFloat(diferenciaMonto) > 0 ? 'warn' : 'info'" :closable="false">
            <template #icon>
              <i class="pi pi-info-circle"></i>
            </template>
            <div class="text-sm">
              <strong>Diferencia:</strong> 
              {{ parseFloat(diferenciaMonto) > 0 ? 'Pagarás' : 'Ahorrarás' }} 
              <strong>${{ Math.abs(diferenciaMonto) }}</strong> 
              {{ parseFloat(diferenciaMonto) > 0 ? 'más' : 'menos' }} que el monto original
              <div class="text-xs mt-1">
                Monto original: ${{ montoTotal?.toFixed(2) || '0.00' }} | 
                Total con cuotas: ${{ (montoPorMes * numeroMeses).toFixed(2) }}
              </div>
            </div>
          </Message>
        </div>
      </div>

      <!-- Resumen de cálculos -->
      <div class="p-3 bg-primary/10 dark:bg-primary/20 rounded-lg border border-primary/30">
        <h4 class="font-semibold mb-2 text-primary">Resumen</h4>
        <div class="grid grid-cols-2 gap-2 text-sm">
          <div>
            <p class="text-surface-600 dark:text-surface-400">Pago mensual:</p>
            <p class="font-bold text-lg">${{ montoPorMes }}</p>
          </div>
          <div>
            <p class="text-surface-600 dark:text-surface-400">Meses restantes:</p>
            <p class="font-bold text-lg">{{ mesesRestantes }}</p>
          </div>
          <div class="col-span-2 mt-2 pt-2 border-t border-primary/30">
            <p class="text-surface-600 dark:text-surface-400">Total a pagar:</p>
            <p class="font-bold text-xl text-primary">${{ totalAPagar }}</p>
          </div>
        </div>
      </div>

      <!-- Advertencia sobre categoría -->
      <Message v-if="!categoryId" severity="warn" :closable="false">
        Debes seleccionar una categoría antes de configurar el MSI
      </Message>

      <!-- Información importante -->
      <Message severity="info" :closable="false">
        <template #icon>
          <i class="pi pi-info-circle"></i>
        </template>
        Los pagos se ejecutarán <strong>automáticamente</strong> cada mes en la fecha de corte de tu tarjeta.
        Se crearán {{ mesesRestantes }} transacciones programadas.
      </Message>

    </form>

    <template #footer>
      <div class="flex justify-end gap-2">
        <Button
          label="Cancelar"
          severity="secondary"
          @click="$emit('update:visible', false)"
          :disabled="loading"
        />
        <Button
          label="Crear MSI"
          icon="pi pi-check"
          @click="handleSubmit"
          :loading="loading"
          :disabled="!categoryId"
        />
      </div>
    </template>
  </Dialog>
</template>
