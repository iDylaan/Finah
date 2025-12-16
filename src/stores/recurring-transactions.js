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
                    cuenta:cuentas!cuenta_id(
                        id, 
                        nombre, 
                        tipo,
                        banco:bancos(id, nombre, nombre_icono, biblioteca_iconos, color)
                    ),
                    cuenta_destino:cuentas!cuenta_destino_id(
                        id, 
                        nombre, 
                        tipo,
                        banco:bancos(id, nombre, nombre_icono, biblioteca_iconos, color)
                    ),
                    categoria:categorias(id, nombre, nombre_icono, biblioteca_iconos)
                `)
                // .is('deleted_at', null) // TODO: Descomentar después de migración
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
            const rpcParams = {
                p_usuario_id: (await supabase.auth.getUser()).data.user.id,
                p_cuenta_id: msiData.cuenta_id,
                p_categoria_id: msiData.categoria_id,
                p_nombre: msiData.nombre,
                p_descripcion: msiData.descripcion || null,
                p_monto_total: msiData.monto_total,
                p_numero_meses: msiData.numero_meses,
                p_meses_ya_pagados: msiData.meses_ya_pagados || 0,
                p_iniciar_siguiente_periodo: msiData.iniciar_siguiente_periodo || false
            }

            // Agregar monto personalizado si existe
            if (msiData.monto_por_mes && msiData.monto_por_mes > 0) {
                rpcParams.p_monto_personalizado_por_mes = msiData.monto_por_mes
            }

            const { data, error: createError } = await supabase.rpc('crear_msi_tarjeta_credito', rpcParams)

            if (createError) throw createError

            // Recargar transacciones
            await fetchRecurringTransactions()

            if (toast) {
                toast.add({
                    severity: 'success',
                    summary: 'Pago Diferido Creado',
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
            // Verificar si es un MSI para usar la función especializada
            const transaction = recurringTransactions.value.find(t => t.id === id)
            
            if (transaction?.es_msi) {
                // Usar función RPC para MSI que restaura el crédito
                const { error: deleteError } = await supabase.rpc('eliminar_msi_tarjeta_credito', {
                    p_usuario_id: (await supabase.auth.getUser()).data.user.id,
                    p_transaccion_periodica_id: id
                })

                if (deleteError) throw deleteError
            } else {
                // Para transacciones periódicas normales, usar DELETE directo
                const { error: deleteError } = await supabase
                    .from('transacciones_periodicas')
                    .delete()
                    .eq('id', id)

                if (deleteError) throw deleteError
            }

            // Remover del store
            recurringTransactions.value = recurringTransactions.value.filter(t => t.id !== id)

            if (toast) {
                toast.add({
                    severity: 'success',
                    summary: 'Eliminado',
                    detail: transaction?.es_msi ? 'Pago diferido eliminado correctamente' : 'Transacción periódica eliminada',
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
                    detail: err.message || 'No se pudo eliminar la transacción',
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

    /**
     * Actualizar meses pagados de un MSI
     */
    const updateMSIPaidMonths = async (msiId, mesesPagados, { toast } = {}) => {
        loading.value = true
        error.value = null

        try {
            // Obtener el MSI actual
            const msi = recurringTransactions.value.find(t => t.id === msiId && t.es_msi)
            if (!msi) {
                throw new Error('MSI no encontrado')
            }

            const mesesAnteriores = msi.meses_pagados || 0
            const diferencia = mesesPagados - mesesAnteriores

            // Actualizar el registro de la transacción periódica
            const { error: updateError } = await supabase
                .from('transacciones_periodicas')
                .update({
                    meses_pagados: mesesPagados,
                    repeticiones_completadas: mesesPagados
                })
                .eq('id', msiId)

            if (updateError) throw updateError

            // Si aumentaron los meses pagados, marcar más ejecuciones como ejecutadas
            if (diferencia > 0) {
                // Obtener ejecuciones pendientes ordenadas por fecha
                const { data: ejecuciones, error: fetchError } = await supabase
                    .from('ejecuciones_transacciones_periodicas')
                    .select('*')
                    .eq('transaccion_periodica_id', msiId)
                    .in('estado', ['pendiente', 'confirmada'])
                    .order('fecha_programada', { ascending: true })
                    .limit(diferencia)

                if (fetchError) throw fetchError

                // Marcar como ejecutadas
                if (ejecuciones && ejecuciones.length > 0) {
                    const idsAMarcar = ejecuciones.map(e => e.id)
                    const { error: markError } = await supabase
                        .from('ejecuciones_transacciones_periodicas')
                        .update({
                            estado: 'ejecutada',
                            fecha_ejecutada: new Date().toISOString(),
                            monto_ejecutado: msi.monto_por_mes
                        })
                        .in('id', idsAMarcar)

                    if (markError) throw markError
                }
            }

            // Si disminuyeron los meses pagados, regresar ejecuciones a pendiente
            if (diferencia < 0) {
                // Obtener ejecuciones ejecutadas ordenadas por fecha DESC
                const { data: ejecuciones, error: fetchError } = await supabase
                    .from('ejecuciones_transacciones_periodicas')
                    .select('*')
                    .eq('transaccion_periodica_id', msiId)
                    .eq('estado', 'ejecutada')
                    .order('fecha_programada', { ascending: false })
                    .limit(Math.abs(diferencia))

                if (fetchError) throw fetchError

                // Marcar como pendientes
                if (ejecuciones && ejecuciones.length > 0) {
                    const idsAMarcar = ejecuciones.map(e => e.id)
                    const { error: markError } = await supabase
                        .from('ejecuciones_transacciones_periodicas')
                        .update({
                            estado: 'pendiente',
                            fecha_ejecutada: null,
                            monto_ejecutado: null
                        })
                        .in('id', idsAMarcar)

                    if (markError) throw markError
                }
            }

            // Recargar transacciones
            await fetchRecurringTransactions()

            if (toast) {
                toast.add({
                    severity: 'success',
                    summary: 'MSI Actualizado',
                    detail: `Se actualizaron los meses pagados a ${mesesPagados}`,
                    life: 4000
                })
            }

            return true
        } catch (err) {
            error.value = err.message
            console.error('💥 Error al actualizar meses pagados:', err)
            
            if (toast) {
                toast.add({
                    severity: 'error',
                    summary: 'Error',
                    detail: err.message || 'No se pudieron actualizar los meses pagados',
                    life: 5000
                })
            }
            
            throw err
        } finally {
            loading.value = false
        }
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
        updateMSIPaidMonths,

        // Acciones - Ejecuciones
        fetchPendingExecutions,
        confirmExecution,
        cancelExecution
    }
})
