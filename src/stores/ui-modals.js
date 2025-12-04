import { ref } from 'vue'
import { defineStore } from 'pinia'

export const useModalsStore = defineStore('modals', () => {
    // Estado del modal de transacciones
    const transactionModalVisible = ref(false)
    const transactionModalType = ref(null) // 'ingreso', 'gasto', 'transferencia'
    const preselectedAccountId = ref(null) // ID de cuenta preseleccionada para transferencias

    // Funciones para controlar el modal
    const openTransactionModal = (type, accountId = null) => {
        transactionModalType.value = type
        preselectedAccountId.value = accountId
        transactionModalVisible.value = true
    }

    const closeTransactionModal = () => {
        transactionModalVisible.value = false
        transactionModalType.value = null
        preselectedAccountId.value = null
    }

    // Shortcuts para tipos específicos
    const openIngresoModal = () => openTransactionModal('ingreso')
    const openGastoModal = () => openTransactionModal('gasto')
    const openTransferenciaModal = (accountId = null) => openTransactionModal('transferencia', accountId)

    return {
        // Estado
        transactionModalVisible,
        transactionModalType,
        preselectedAccountId,

        // Acciones
        openTransactionModal,
        closeTransactionModal,
        openIngresoModal,
        openGastoModal,
        openTransferenciaModal
    }
})
