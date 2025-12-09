import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { supabase } from '@/lib/supabase'

export const useRecurringTransactionsStore = defineStore('recurringTransactions', () => {
    // Estado
    const recurringTransactions = ref([])
    const pendingExecutions = ref([])
    const loading = ref(false)
    const error = ref(null)

    // Computed
    const msiTransactions = computed(() => 
        recurringTransactions.value.filter(t => t.es_msi)
    )

    const activeTransactions = computed(() => 
        recurringTransactions.value.filter(t => t.activa)
    )

    const transactionsRequiringConfirmation = computed(() => 
        recurringTransactions.value.filter(t => t.requiere_confirmacion && t.activa)
    )

    // ============================================
    // FUNCIONES PARA TRANSACCIONES PERIÓDICAS
    // ============================================

    /**
     * Obtener todas las transacciones periódicas del usuario
     */
    const fetchRecurringTransactions = async ({ toast } = {}) => {
        loading.value = true
        error.value = null

        try {
            const { data, error: fetchError } = await supabase
                .from('transacciones_periodicas')
                .select(`
                    *,
                    cuenta:cuentas!cuenta_id(id, nombre, tipo, icono),
                    cuenta_destino:cuentas!cuenta_destino_id(id, nombre, tipo, icono),
                    categoria:categorias(id, nombre, nombre_icono, biblioteca_iconos)
                `)
                .order('created_at', { ascending: false })

            if (fetchError) throw fetchError

            recurringTransactions.value = data || []

            return data
        } catch (err) {
            error.value = err.message
            console.error('💥 Error al obtener transacciones periódicas:', err)
            
            if (toast) {
                toast.add({
                    severity: 'error',
                    summary: 'Error',
                    detail: 'No se pudieron cargar las transacciones programadas',
                    life: 5000
                })
            }
            
            return null
        } finally {
            loading.value = false
        }
    }

    /**
     * Crear MSI (Meses Sin Intereses) en tarjeta de crédito
     */
    const createMSI = async (msiData, { toast } = {}) => {
        loading.value = true
        error.value = null

        try {
            const { data, error: createError } = await supabase.rpc('crear_msi_tarjeta_credito', {
                p_usuario_id: (await supabase.auth.getUser()).data.user.id,
                p_cuenta_id: msiData.cuenta_id,
                p_categoria_id: msiData.categoria_id,
                p_nombre: msiData.nombre,
                p_descripcion: msiData.descripcion || null,
                p_monto_total: msiData.monto_total,
                p_numero_meses: msiData.numero_meses,
                p_meses_ya_pagados: msiData.meses_pagados || 0
            })

            if (createError) throw createError

            // Recargar transacciones
            await fetchRecurringTransactions()

            if (toast) {
                toast.add({
                    severity: 'success',
                    summary: 'MSI Creado',
                    detail: `Se creó el pago diferido de ${msiData.numero_meses} meses`,
                    life: 4000
                })
            }

            return data
        } catch (err) {
            error.value = err.message
            console.error('💥 Error al crear MSI:', err)
            
            if (toast) {
                toast.add({
                    severity: 'error',
                    summary: 'Error',
                    detail: err.message || 'No se pudo crear el MSI',
                    life: 5000
                })
            }
            
            throw err
        } finally {
            loading.value = false
        }
    }

    /**
     * Crear transacción periódica genérica
     */
    const createRecurringTransaction = async (transactionData, { toast } = {}) => {
        loading.value = true
        error.value = null

        try {
            const { data: user } = await supabase.auth.getUser()

            const { data, error: createError } = await supabase
                .from('transacciones_periodicas')
                .insert({
                    usuario_id: user.user.id,
                    ...transactionData
                })
                .select()
                .single()

            if (createError) throw createError

            // Recargar transacciones
            await fetchRecurringTransactions()

            if (toast) {
                toast.add({
                    severity: 'success',
                    summary: 'Transacción Programada',
                    detail: 'Se creó la transacción periódica exitosamente',
                    life: 4000
                })
            }

            return data
        } catch (err) {
            error.value = err.message
            console.error('💥 Error al crear transacción periódica:', err)
            
            if (toast) {
                toast.add({
                    severity: 'error',
                    summary: 'Error',
                    detail: 'No se pudo crear la transacción programada',
                    life: 5000
                })
            }
            
            throw err
        } finally {
            loading.value = false
        }
    }

    /**
     * Actualizar transacción periódica
     */
    const updateRecurringTransaction = async (id, updates, { toast } = {}) => {
        loading.value = true
        error.value = null

        try {
            const { data, error: updateError } = await supabase
                .from('transacciones_periodicas')
                .update(updates)
                .eq('id', id)
                .select()
                .single()

            if (updateError) throw updateError

            // Actualizar en el store
            const index = recurringTransactions.value.findIndex(t => t.id === id)
            if (index !== -1) {
                recurringTransactions.value[index] = data
            }

            if (toast) {
                toast.add({
                    severity: 'success',
                    summary: 'Actualizado',
                    detail: 'Transacción periódica actualizada',
                    life: 3000
                })
            }

            return data
        } catch (err) {
            error.value = err.message
            console.error('💥 Error al actualizar transacción periódica:', err)
            
            if (toast) {
                toast.add({
                    severity: 'error',
                    summary: 'Error',
                    detail: 'No se pudo actualizar la transacción',
                    life: 5000
                })
            }
            
            throw err
        } finally {
            loading.value = false
        }
    }

    /**
     * Eliminar transacción periódica
     */
    const deleteRecurringTransaction = async (id, { toast } = {}) => {
        loading.value = true
        error.value = null

        try {
            const { error: deleteError } = await supabase
                .from('transacciones_periodicas')
                .delete()
                .eq('id', id)

            if (deleteError) throw deleteError

            // Remover del store
            recurringTransactions.value = recurringTransactions.value.filter(t => t.id !== id)

            if (toast) {
                toast.add({
                    severity: 'success',
                    summary: 'Eliminado',
                    detail: 'Transacción periódica eliminada',
                    life: 3000
                })
            }

            return true
        } catch (err) {
            error.value = err.message
            console.error('💥 Error al eliminar transacción periódica:', err)
            
            if (toast) {
                toast.add({
                    severity: 'error',
                    summary: 'Error',
                    detail: 'No se pudo eliminar la transacción',
                    life: 5000
                })
            }
            
            throw err
        } finally {
            loading.value = false
        }
    }

    /**
     * Pausar/Reanudar transacción periódica
     */
    const toggleRecurringTransaction = async (id, { toast } = {}) => {
        const transaction = recurringTransactions.value.find(t => t.id === id)
        if (!transaction) return

        return updateRecurringTransaction(
            id, 
            { activa: !transaction.activa },
            { toast }
        )
    }

    // ============================================
    // FUNCIONES PARA EJECUCIONES
    // ============================================

    /**
     * Obtener ejecuciones pendientes
     */
    const fetchPendingExecutions = async ({ toast } = {}) => {
        loading.value = true
        error.value = null

        try {
            const { data, error: fetchError } = await supabase
                .from('ejecuciones_transacciones_periodicas')
                .select(`
                    *,
                    transaccion_periodica:transacciones_periodicas(
                        *,
                        cuenta:cuentas!cuenta_id(id, nombre, tipo),
                        categoria:categorias(id, nombre)
                    )
                `)
                .in('estado', ['pendiente', 'confirmada'])
                .order('fecha_programada', { ascending: true })

            if (fetchError) throw fetchError

            pendingExecutions.value = data || []

            return data
        } catch (err) {
            error.value = err.message
            console.error('💥 Error al obtener ejecuciones pendientes:', err)
            
            if (toast) {
                toast.add({
                    severity: 'error',
                    summary: 'Error',
                    detail: 'No se pudieron cargar las ejecuciones pendientes',
                    life: 5000
                })
            }
            
            return null
        } finally {
            loading.value = false
        }
    }

    /**
     * Confirmar ejecución de transacción periódica
     */
    const confirmExecution = async (executionId, { toast } = {}) => {
        loading.value = true
        error.value = null

        try {
            const { data, error: updateError } = await supabase
                .from('ejecuciones_transacciones_periodicas')
                .update({
                    estado: 'confirmada',
                    fecha_confirmada: new Date().toISOString()
                })
                .eq('id', executionId)
                .select()
                .single()

            if (updateError) throw updateError

            // Actualizar en el store
            const index = pendingExecutions.value.findIndex(e => e.id === executionId)
            if (index !== -1) {
                pendingExecutions.value[index] = data
            }

            if (toast) {
                toast.add({
                    severity: 'success',
                    summary: 'Confirmado',
                    detail: 'Transacción confirmada para ejecución',
                    life: 3000
                })
            }

            return data
        } catch (err) {
            error.value = err.message
            console.error('💥 Error al confirmar ejecución:', err)
            
            if (toast) {
                toast.add({
                    severity: 'error',
                    summary: 'Error',
                    detail: 'No se pudo confirmar la transacción',
                    life: 5000
                })
            }
            
            throw err
        } finally {
            loading.value = false
        }
    }

    /**
     * Cancelar ejecución de transacción periódica
     */
    const cancelExecution = async (executionId, { toast } = {}) => {
        loading.value = true
        error.value = null

        try {
            const { data, error: updateError } = await supabase
                .from('ejecuciones_transacciones_periodicas')
                .update({
                    estado: 'cancelada'
                })
                .eq('id', executionId)
                .select()
                .single()

            if (updateError) throw updateError

            // Remover de pendientes
            pendingExecutions.value = pendingExecutions.value.filter(e => e.id !== executionId)

            if (toast) {
                toast.add({
                    severity: 'info',
                    summary: 'Cancelado',
                    detail: 'Ejecución cancelada',
                    life: 3000
                })
            }

            return data
        } catch (err) {
            error.value = err.message
            console.error('💥 Error al cancelar ejecución:', err)
            
            if (toast) {
                toast.add({
                    severity: 'error',
                    summary: 'Error',
                    detail: 'No se pudo cancelar la ejecución',
                    life: 5000
                })
            }
            
            throw err
        } finally {
            loading.value = false
        }
    }

    return {
        // Estado
        recurringTransactions,
        pendingExecutions,
        loading,
        error,

        // Computed
        msiTransactions,
        activeTransactions,
        transactionsRequiringConfirmation,

        // Acciones - Transacciones Periódicas
        fetchRecurringTransactions,
        createMSI,
        createRecurringTransaction,
        updateRecurringTransaction,
        deleteRecurringTransaction,
        toggleRecurringTransaction,

        // Acciones - Ejecuciones
        fetchPendingExecutions,
        confirmExecution,
        cancelExecution
    }
})
