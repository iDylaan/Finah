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

    // ============================================
    // MODALS DE CATEGORÍAS
    // ============================================
    
    // Estado del modal de grupo de categorías
    const categoryGroupModalVisible = ref(false)
    const categoryGroupModalMode = ref('create') // 'create' | 'edit'
    const categoryGroupEditId = ref(null)
    
    // Estado del modal de categoría
    const categoryModalVisible = ref(false)
    const categoryModalMode = ref('create') // 'create' | 'edit' | 'view'
    const categoryEditId = ref(null)
    const categoryGroupId = ref(null)
    const categoryData = ref(null)
    
    // Funciones para grupo de categorías
    const openCategoryGroupModal = (groupId = null) => {
        if (groupId) {
            categoryGroupModalMode.value = 'edit'
            categoryGroupEditId.value = groupId
        } else {
            categoryGroupModalMode.value = 'create'
            categoryGroupEditId.value = null
        }
        categoryGroupModalVisible.value = true
    }
    
    const closeCategoryGroupModal = () => {
        categoryGroupModalVisible.value = false
        categoryGroupModalMode.value = 'create'
        categoryGroupEditId.value = null
    }
    
    // Funciones para categoría
    const openCategoryModal = (options = {}) => {
        const { mode = 'create', categoryId = null, groupId = null, category = null } = options
        
        categoryModalMode.value = mode
        categoryEditId.value = categoryId
        categoryGroupId.value = groupId
        categoryData.value = category
        categoryModalVisible.value = true
    }
    
    const closeCategoryModal = () => {
        categoryModalVisible.value = false
        categoryModalMode.value = 'create'
        categoryEditId.value = null
        categoryGroupId.value = null
        categoryData.value = null
    }
    
    // Shortcuts para categorías
    const openNewCategoryModal = (groupId) => {
        openCategoryModal({ mode: 'create', groupId })
    }
    
    const openEditCategoryModal = (categoryId, category = null) => {
        openCategoryModal({ mode: 'edit', categoryId, category })
    }
    
    const openViewCategoryModal = (categoryId, category = null) => {
        openCategoryModal({ mode: 'view', categoryId, category })
    }

    // ============================================
    // MODAL DE TRANSACCIONES PERIÓDICAS
    // ============================================
    
    const recurringTransactionModalVisible = ref(false)
    const recurringTransactionEditData = ref(null)
    
    const openRecurringTransactionModal = (editData = null) => {
        recurringTransactionEditData.value = editData
        recurringTransactionModalVisible.value = true
    }
    
    const closeRecurringTransactionModal = () => {
        recurringTransactionModalVisible.value = false
        recurringTransactionEditData.value = null
    }

    return {
        // Estado transacciones
        transactionModalVisible,
        transactionModalType,
        preselectedAccountId,

        // Acciones transacciones
        openTransactionModal,
        closeTransactionModal,
        openIngresoModal,
        openGastoModal,
        openTransferenciaModal,
        
        // Estado grupo de categorías
        categoryGroupModalVisible,
        categoryGroupModalMode,
        categoryGroupEditId,
        
        // Estado categoría
        categoryModalVisible,
        categoryModalMode,
        categoryEditId,
        categoryGroupId,
        categoryData,
        
        // Acciones grupo de categorías
        openCategoryGroupModal,
        closeCategoryGroupModal,
        
        // Acciones categoría
        openCategoryModal,
        closeCategoryModal,
        openNewCategoryModal,
        openEditCategoryModal,
        openViewCategoryModal,
        
        // Estado transacciones periódicas
        recurringTransactionModalVisible,
        recurringTransactionEditData,
        
        // Acciones transacciones periódicas
        openRecurringTransactionModal,
        closeRecurringTransactionModal
    }
})
