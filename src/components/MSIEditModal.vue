<script setup>
import { ref, computed, watch } from 'vue'
import { useRecurringTransactionsStore } from '@/stores/recurring-transactions'
import { useToast } from 'primevue/usetoast'

const props = defineProps({
  visible: {
    type: Boolean,
    default: false
  },
  msi: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['update:visible', 'msi-updated'])

const toast = useToast()
const recurringStore = useRecurringTransactionsStore()

// Estado del formulario
const mesesPagados = ref(0)
const loading = ref(false)
const errors = ref({})

// Cálculos
const mesesRestantes = computed(() => {
  if (!props.msi) return 0
  return props.msi.numero_meses_total - mesesPagados.value
})

const montoRestante = computed(() => {
  if (!props.msi) return 0
  return mesesRestantes.value * parseFloat(props.msi.monto_por_mes || 0)
})

const montoPagado = computed(() => {
  if (!props.msi) return 0
  return mesesPagados.value * parseFloat(props.msi.monto_por_mes || 0)
})

// Validación
const validate = () => {
  errors.value = {}
  
  if (mesesPagados.value < 0 || mesesPagados.value > props.msi?.numero_meses_total) {
    errors.value.mesesPagados = `Debe estar entre 0 y ${props.msi?.numero_meses_total}`
  }
  
  return Object.keys(errors.value).length === 0
}

// Guardar cambios
const handleSave = async () => {
  if (!validate()) return
  
  loading.value = true
  
  try {
    // Actualizar el MSI con los nuevos meses pagados
    await recurringStore.updateMSIPaidMonths(props.msi.id, mesesPagados.value, { toast })
    
    emit('msi-updated')
    emit('update:visible', false)
  } catch (error) {
    console.error('Error actualizando MSI:', error)
  } finally {
    loading.value = false
  }
}

const handleClose = () => {
  if (!loading.value) {
    emit('update:visible', false)
  }
}

// Inicializar cuando se abre el modal
watch(() => props.visible, (newVal) => {
  if (newVal && props.msi) {
    mesesPagados.value = props.msi.meses_pagados || 0
    errors.value = {}
  }
})
</script>

<template>
  <Dialog
    :visible="visible"
    @update:visible="$emit('update:visible', $event)"
    modal
    :header="`Editar ${msi?.nombre || 'MSI'}`"
    :style="{ width: '32rem' }"
    :breakpoints="{ '768px': '100vw' }"
    class="mobile-fullscreen-dialog"
    :closable="!loading"
  >
    <div v-if="msi" class="flex flex-col gap-4">
      <!-- Información del MSI -->
      <div class="p-3 bg-surface-50 dark:bg-surface-800 rounded-lg">
        <div class="grid grid-cols-2 gap-3 text-sm">
          <div>
            <p class="text-surface-600 dark:text-surface-400">Monto total</p>
            <p class="font-bold">${{ msi.monto_total_msi?.toLocaleString('es-MX') }}</p>
          </div>
          <div>
            <p class="text-surface-600 dark:text-surface-400">Pago mensual</p>
            <p class="font-bold text-primary">${{ msi.monto_por_mes?.toLocaleString('es-MX') }}</p>
          </div>
          <div class="col-span-2">
            <p class="text-surface-600 dark:text-surface-400">Plazo total</p>
            <p class="font-bold">{{ msi.numero_meses_total }} meses</p>
          </div>
        </div>
      </div>

      <!-- Meses pagados -->
      <div class="flex flex-col gap-2">
        <label for="meses-pagados" class="font-medium">
          ¿Cuántos meses has pagado? <span class="text-red-500">*</span>
        </label>
        <InputNumber
          id="meses-pagados"
          v-model="mesesPagados"
          :min="0"
          :max="msi.numero_meses_total"
          :invalid="!!errors.mesesPagados"
          showButtons
          buttonLayout="horizontal"
          :step="1"
          :disabled="loading"
        >
          <template #incrementbuttonicon>
            <span class="pi pi-plus" />
          </template>
          <template #decrementbuttonicon>
            <span class="pi pi-minus" />
          </template>
        </InputNumber>
        <small v-if="errors.mesesPagados" class="text-red-500">{{ errors.mesesPagados }}</small>
      </div>

      <!-- Resumen actualizado -->
      <div class="p-3 bg-primary/10 dark:bg-primary/20 rounded-lg border border-primary/30">
        <h3 class="font-semibold mb-2 text-primary">📊 Resumen Actualizado</h3>
        <div class="grid grid-cols-2 gap-2 text-sm">
          <div>
            <p class="text-surface-600 dark:text-surface-400">Meses pagados:</p>
            <p class="font-bold text-lg">{{ mesesPagados }} / {{ msi.numero_meses_total }}</p>
          </div>
          <div>
            <p class="text-surface-600 dark:text-surface-400">Progreso:</p>
            <p class="font-bold text-lg">{{ Math.round((mesesPagados / msi.numero_meses_total) * 100) }}%</p>
          </div>
          <div class="col-span-2 mt-2 pt-2 border-t border-primary/30">
            <p class="text-surface-600 dark:text-surface-400">Monto ya pagado:</p>
            <p class="font-bold text-lg text-green-600">${{ montoPagado.toLocaleString('es-MX') }}</p>
          </div>
          <div class="col-span-2">
            <p class="text-surface-600 dark:text-surface-400">Monto restante:</p>
            <p class="font-bold text-xl text-primary">${{ montoRestante.toLocaleString('es-MX') }}</p>
          </div>
          <div class="col-span-2">
            <p class="text-surface-600 dark:text-surface-400">Meses restantes:</p>
            <p class="font-bold text-lg">{{ mesesRestantes }}</p>
          </div>
        </div>
      </div>

      <!-- Información importante -->
      <Message severity="info" :closable="false">
        <template #icon>
          <i class="pi pi-info-circle"></i>
        </template>
        Al actualizar los meses pagados, se ajustará el saldo total de tu tarjeta y las cuotas pendientes.
      </Message>
    </div>

    <template #footer>
      <div class="flex justify-end gap-2">
        <Button
          label="Cancelar"
          severity="secondary"
          outlined
          @click="handleClose"
          :disabled="loading"
        />
        <Button
          label="Guardar Cambios"
          @click="handleSave"
          :loading="loading"
          :disabled="loading"
        />
      </div>
    </template>
  </Dialog>
</template>
