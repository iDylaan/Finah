<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRecurringTransactionsStore } from '@/stores/recurring-transactions'
import { useAccountsStore } from '@/stores/accounts'
import { useToast } from 'primevue/usetoast'
import { useConfirm } from 'primevue/useconfirm'
import MSIEditModal from './MSIEditModal.vue'

const props = defineProps({
  visible: {
    type: Boolean,
    default: false
  },
  creditCardId: {
    type: [String, Number],
    default: null
  }
})

const emit = defineEmits(['update:visible', 'msi-deleted'])

const toast = useToast()
const confirm = useConfirm()
const recurringStore = useRecurringTransactionsStore()
const accountsStore = useAccountsStore()

// Estado
const loading = ref(false)
const selectedMSI = ref(null)
const showEditModal = ref(false)

// Obtener la tarjeta de crédito
const creditCard = computed(() => {
  if (!props.creditCardId) return null
  return accountsStore.accounts.find(acc => acc.id === props.creditCardId)
})

// MSI de esta tarjeta
const msiList = computed(() => {
  if (!props.creditCardId) return []
  return recurringStore.msiTransactions.filter(
    msi => msi.cuenta_id === props.creditCardId
  )
})

const hasMSI = computed(() => msiList.value.length > 0)

// Cargar MSI
const loadMSI = async () => {
  loading.value = true
  try {
    await recurringStore.fetchRecurringTransactions({ toast })
  } catch (error) {
    console.error('Error al cargar MSI:', error)
  } finally {
    loading.value = false
  }
}

// Calcular progreso
const calcularProgreso = (msi) => {
  if (!msi.numero_meses_total) return 0
  const pagados = msi.meses_pagados || 0
  return Math.round((pagados / msi.numero_meses_total) * 100)
}

// Obtener severidad según progreso
const getSeverityProgreso = (progreso) => {
  if (progreso >= 75) return 'success'
  if (progreso >= 50) return 'info'
  if (progreso >= 25) return 'warn'
  return 'danger'
}

// Formatear fecha
const formatearFecha = (fecha) => {
  if (!fecha) return 'No programada'
  const date = new Date(fecha)
  return date.toLocaleDateString('es-MX', {
    day: 'numeric',
    month: 'short',
    year: 'numeric'
  })
}

// Pausar/Reanudar MSI
const toggleMSI = async (msi) => {
  try {
    await recurringStore.toggleRecurringTransaction(msi.id, { toast })
    await loadMSI()
  } catch (error) {
    console.error('Error al pausar/reanudar MSI:', error)
  }
}

// Eliminar MSI
const eliminarMSI = (msi) => {
  confirm.require({
    message: `¿Eliminar el MSI "${msi.nombre}"? Esto eliminará también todas las ejecuciones programadas.`,
    header: 'Confirmar Eliminación',
    icon: 'pi pi-exclamation-triangle',
    rejectLabel: 'Cancelar',
    acceptLabel: 'Eliminar',
    acceptClass: 'p-button-danger',
    accept: async () => {
      try {
        await recurringStore.deleteRecurringTransaction(msi.id, { toast })
        await loadMSI()
        // Emitir evento para que el padre refresque la cuenta
        emit('msi-deleted')
      } catch (error) {
        console.error('Error al eliminar MSI:', error)
      }
    }
  })
}

// Editar MSI
const editarMSI = (msi) => {
  selectedMSI.value = msi
  showEditModal.value = true
}

// Manejar actualización de MSI
const handleMSIUpdated = async () => {
  showEditModal.value = false
  selectedMSI.value = null
  await loadMSI()
  // Emitir evento para que el padre refresque la cuenta
  emit('msi-deleted') // Reutilizamos el mismo evento ya que el efecto es el mismo
}

// Lifecycle
onMounted(() => {
  loadMSI()
})

// Watch para recargar cuando se abre el modal
watch(() => props.visible, (newVal) => {
  if (newVal) {
    loadMSI()
  }
})
</script>

<template>
  <Dialog
    :visible="visible"
    @update:visible="$emit('update:visible', $event)"
    modal
    :header="creditCard ? `Pagos Diferidos - ${creditCard.nombre}` : 'Pagos Diferidos'"
    :style="{ width: '42rem' }"
    :breakpoints="{ '768px': '100vw' }"
    class="mobile-fullscreen-dialog"
    :contentStyle="{ maxHeight: 'calc(100vh - 120px)', overflowY: 'auto' }"
  >
    <!-- Loading -->
    <div v-if="loading" class="flex justify-center items-center py-8">
      <ProgressSpinner style="width: 50px; height: 50px" />
    </div>

    <!-- Lista de MSI -->
    <div v-else-if="hasMSI" class="flex flex-col gap-3">
      <div
        v-for="msi in msiList"
        :key="msi.id"
        class="p-4 border border-surface-200 dark:border-surface-700 rounded-lg hover:bg-surface-50 dark:hover:bg-surface-800 transition-colors"
      >
        <!-- Header -->
        <div class="flex justify-between items-start mb-3">
          <div class="flex-1">
            <h3 class="font-semibold text-lg flex items-center gap-2">
              {{ msi.nombre }}
              <Tag v-if="!msi.activa" severity="warn" value="Pausado" />
            </h3>
            <p v-if="msi.descripcion" class="text-sm text-surface-600 dark:text-surface-400 mt-1">
              {{ msi.descripcion }}
            </p>
          </div>
          
          <!-- Menú de acciones -->
          <Button
            icon="pi pi-ellipsis-v"
            text
            rounded
            severity="secondary"
            @click="(event) => $refs[`menu-${msi.id}`][0].toggle(event)"
          />
          <Menu :ref="`menu-${msi.id}`" :model="[
            {
              label: msi.activa ? 'Pausar' : 'Reanudar',
              icon: msi.activa ? 'pi pi-pause' : 'pi pi-play',
              command: () => toggleMSI(msi)
            },
            {
              label: 'Editar',
              icon: 'pi pi-pencil',
              command: () => editarMSI(msi)
            },
            {
              separator: true
            },
            {
              label: 'Eliminar',
              icon: 'pi pi-trash',
              class: 'text-red-500',
              command: () => eliminarMSI(msi)
            }
          ]" popup />
        </div>

        <!-- Información principal -->
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-3">
          <div>
            <p class="text-xs text-surface-600 dark:text-surface-400">Monto total</p>
            <p class="font-bold">${{ msi.monto_total_msi?.toLocaleString('es-MX') }}</p>
          </div>
          <div>
            <p class="text-xs text-surface-600 dark:text-surface-400">Pago mensual</p>
            <p class="font-bold text-primary">${{ msi.monto_por_mes?.toLocaleString('es-MX') }}</p>
          </div>
          <div>
            <p class="text-xs text-surface-600 dark:text-surface-400">Plazo</p>
            <p class="font-bold">{{ msi.numero_meses_total }} meses</p>
          </div>
          <div>
            <p class="text-xs text-surface-600 dark:text-surface-400">Próximo pago</p>
            <p class="font-bold text-sm">{{ formatearFecha(msi.proxima_ejecucion) }}</p>
          </div>
        </div>

        <!-- Barra de progreso -->
        <div class="mb-2">
          <div class="flex justify-between items-center mb-1">
            <span class="text-xs text-surface-600 dark:text-surface-400">
              Progreso: {{ msi.meses_pagados || 0 }} de {{ msi.numero_meses_total }} meses
            </span>
            <span class="text-xs font-semibold">{{ calcularProgreso(msi) }}%</span>
          </div>
          <ProgressBar
            :value="calcularProgreso(msi)"
            :showValue="false"
            :severity="getSeverityProgreso(calcularProgreso(msi))"
            style="height: 8px"
          />
        </div>

        <!-- Categoría -->
        <div v-if="msi.categoria" class="flex items-center gap-2 text-sm text-surface-600 dark:text-surface-400">
          <i v-if="msi.categoria.biblioteca_iconos === 'primevue'" :class="msi.categoria.nombre_icono" class="text-xs"></i>
          <span v-else-if="msi.categoria.biblioteca_iconos === 'material'" class="material-symbols-outlined text-base">{{ msi.categoria.nombre_icono }}</span>
          <span>{{ msi.categoria.nombre }}</span>
        </div>
      </div>
    </div>

    <!-- Estado vacío -->
    <div v-else class="text-center py-8">
      <i class="pi pi-credit-card text-6xl text-surface-300 dark:text-surface-600 mb-4"></i>
      <p class="text-surface-600 dark:text-surface-400 mb-2">No tienes pagos diferidos registrados</p>
      <p class="text-sm text-surface-500 dark:text-surface-500">
        Los pagos diferidos a meses aparecerán aquí
      </p>
    </div>

    <template #footer>
      <Button
        label="Cerrar"
        severity="secondary"
        @click="$emit('update:visible', false)"
      />
    </template>
  </Dialog>

  <!-- Modal de Edición -->
  <MSIEditModal
    v-model:visible="showEditModal"
    :msi="selectedMSI"
    @msi-updated="handleMSIUpdated"
  />
</template>
