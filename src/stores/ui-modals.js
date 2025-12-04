import { ref } from 'vue'
import { defineStore } from 'pinia'

export const useModalsStore = defineStore('modals', () => {
    // Estado del modal de transacciones
    const transactionModalVisible = ref(false)
    const transactionModalType = ref(null) // 'ingreso', 'gasto', 'transferencia'

    // Funciones para controlar el modal
    const openTransactionModal = (type) => {
        transactionModalType.value = type
        transactionModalVisible.value = true
    }

    const closeTransactionModal = () => {
        transactionModalVisible.value = false
        transactionModalType.value = null
    }

    // Shortcuts para tipos específicos
    const openIngresoModal = () => openTransactionModal('ingreso')
    const openGastoModal = () => openTransactionModal('gasto')
    const openTransferenciaModal = () => openTransactionModal('transferencia')

    return {
        // Estado
        transactionModalVisible,
        transactionModalType,

        // Acciones
        openTransactionModal,
        closeTransactionModal,
        openIngresoModal,
        openGastoModal,
        openTransferenciaModal
    }
})
