import { ref } from 'vue'
import { defineStore } from 'pinia'
import { supabase } from '@/lib/supabase.js'

export const useTransactionsStore = defineStore('transactions', () => {
    // Estados
    const transactions = ref([])
    const accountTransactions = ref([])
    const loading = ref(false)

    // FUNCIÓN PARA CREAR INGRESO
    const createIngreso = async (ingresoData, { toast }) => {
        loading.value = true

        try {
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }

            console.log('💰 Creando ingreso:', ingresoData)

            // 1. Obtener la cuenta para determinar el tipo
            const { data: cuenta, error: cuentaError } = await supabase
                .from('cuentas')
                .select('tipo, limite_credito, credito_disponible')
                .eq('id', ingresoData.cuenta_id)
                .single()

            if (cuentaError) {
                throw new Error('Error al obtener información de la cuenta')
            }

            // 2. Crear la transacción de ingreso
            const transaccionInsert = {
                usuario_id: user.id,
                cuenta_id: ingresoData.cuenta_id,
                categoria_id: ingresoData.categoria_id,
                nivel_id: ingresoData.nivel_id || null,
                tipo: 'ingreso',
                severidad: 'exito', // Los ingresos son eventos positivos
                monto: parseFloat(ingresoData.monto),
                fecha_ocurrencia: ingresoData.fecha_ocurrencia,
                descripcion: ingresoData.descripcion?.trim() || null,
                url_recibo: ingresoData.url_recibo || null,
                metadatos: ingresoData.metadatos || {}
            }

            const { data: newTransaction, error: transactionError } = await supabase
                .from('transacciones')
                .insert([transaccionInsert])
                .select('*')
                .single()

            if (transactionError) {
                console.error('💥 Error creando transacción:', transactionError)
                throw transactionError
            }

            console.log('✅ Transacción de ingreso creada:', newTransaction)

            // 3. Actualizar el saldo de la cuenta según el tipo
            let updateData = {}

            if (cuenta.tipo === 'credit_card') {
                // Para tarjetas de crédito: aumentar crédito disponible
                const nuevoCredito = parseFloat(cuenta.credito_disponible) + parseFloat(ingresoData.monto)
                updateData = {
                    credito_disponible: nuevoCredito,
                    fecha_actualizacion: new Date().toISOString()
                }
                console.log('💳 Actualizando tarjeta de crédito - Nuevo crédito disponible:', nuevoCredito)
            } else {
                // Para otras cuentas: aumentar saldo
                const { data: cuentaActual } = await supabase
                    .from('cuentas')
                    .select('saldo')
                    .eq('id', ingresoData.cuenta_id)
                    .single()

                const nuevoSaldo = parseFloat(cuentaActual.saldo) + parseFloat(ingresoData.monto)
                updateData = {
                    saldo: nuevoSaldo,
                    fecha_actualizacion: new Date().toISOString()
                }
                console.log('🏦 Actualizando cuenta - Nuevo saldo:', nuevoSaldo)
            }

            const { error: updateError } = await supabase
                .from('cuentas')
                .update(updateData)
                .eq('id', ingresoData.cuenta_id)

            if (updateError) {
                console.error('💥 Error actualizando cuenta:', updateError)
                throw updateError
            }

            console.log('✅ Cuenta actualizada exitosamente')

            // Mostrar mensaje de éxito
            if (toast) {
                toast.add({
                    severity: 'success',
                    summary: 'Ingreso Registrado',
                    detail: `Se registró un ingreso de $${parseFloat(ingresoData.monto).toLocaleString('es-MX', { minimumFractionDigits: 2 })}`,
                    life: 3000
                })
            }

            return newTransaction

        } catch (error) {
            console.error('💥 Error creando ingreso:', error)

            if (toast) {
                toast.add({
                    severity: 'error',
                    summary: 'Error',
                    detail: error.message || 'Error registrando el ingreso',
                    life: 5000
                })
            }

            throw error

        } finally {
            loading.value = false
        }
    }

    // FUNCIÓN PARA CREAR GASTO
    const createGasto = async (gastoData, { toast }) => {
        loading.value = true

        try {
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }

            console.log('💸 Creando gasto:', gastoData)

            // 1. Obtener la cuenta para determinar el tipo y verificar saldo
            const { data: cuenta, error: cuentaError } = await supabase
                .from('cuentas')
                .select('tipo, saldo, credito_disponible')
                .eq('id', gastoData.cuenta_id)
                .single()

            if (cuentaError) {
                throw new Error('Error al obtener información de la cuenta')
            }

            // 2. Verificar que haya saldo suficiente
            const montoGasto = parseFloat(gastoData.monto)
            if (cuenta.tipo === 'credit_card') {
                if (parseFloat(cuenta.credito_disponible) < montoGasto) {
                    throw new Error('Crédito disponible insuficiente')
                }
            } else {
                if (parseFloat(cuenta.saldo) < montoGasto) {
                    throw new Error('Saldo insuficiente')
                }
            }

            // 3. Crear la transacción de gasto
            const transaccionInsert = {
                usuario_id: user.id,
                cuenta_id: gastoData.cuenta_id,
                categoria_id: gastoData.categoria_id,
                nivel_id: gastoData.nivel_id,
                tipo: 'gasto',
                severidad: 'advertencia', // Los gastos son eventos de advertencia
                monto: montoGasto,
                fecha_ocurrencia: gastoData.fecha_ocurrencia,
                descripcion: gastoData.descripcion?.trim() || null,
                url_recibo: gastoData.url_recibo || null,
                metadatos: gastoData.metadatos || {}
            }

            const { data: newTransaction, error: transactionError } = await supabase
                .from('transacciones')
                .insert([transaccionInsert])
                .select('*')
                .single()

            if (transactionError) {
                console.error('💥 Error creando transacción de gasto:', transactionError)
                throw transactionError
            }

            console.log('✅ Transacción de gasto creada:', newTransaction)

            // 4. Actualizar el saldo de la cuenta según el tipo
            let updateData = {}

            if (cuenta.tipo === 'credit_card') {
                // Para tarjetas de crédito: disminuir crédito disponible
                const nuevoCredito = parseFloat(cuenta.credito_disponible) - montoGasto
                updateData = {
                    credito_disponible: nuevoCredito,
                    fecha_actualizacion: new Date().toISOString()
                }
                console.log('💳 Actualizando tarjeta de crédito - Nuevo crédito disponible:', nuevoCredito)
            } else {
                // Para otras cuentas: disminuir saldo
                const nuevoSaldo = parseFloat(cuenta.saldo) - montoGasto
                updateData = {
                    saldo: nuevoSaldo,
                    fecha_actualizacion: new Date().toISOString()
                }
                console.log('🏦 Actualizando cuenta - Nuevo saldo:', nuevoSaldo)
            }

            const { error: updateError } = await supabase
                .from('cuentas')
                .update(updateData)
                .eq('id', gastoData.cuenta_id)

            if (updateError) {
                console.error('💥 Error actualizando cuenta:', updateError)
                throw updateError
            }

            console.log('✅ Cuenta actualizada exitosamente')

            // Mostrar mensaje de éxito
            if (toast) {
                toast.add({
                    severity: 'success',
                    summary: 'Gasto Registrado',
                    detail: `Se registró un gasto de $${montoGasto.toLocaleString('es-MX', { minimumFractionDigits: 2 })}`,
                    life: 3000
                })
            }

            return newTransaction

        } catch (error) {
            console.error('💥 Error creando gasto:', error)

            if (toast) {
                toast.add({
                    severity: 'error',
                    summary: 'Error',
                    detail: error.message || 'Error registrando el gasto',
                    life: 5000
                })
            }

            throw error

        } finally {
            loading.value = false
        }
    }

    // FUNCIÓN PARA OBTENER TRANSACCIONES POR CUENTA
    const fetchTransactionsByAccount = async (accountId, { toast }) => {
        loading.value = true

        try {
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }

            console.log('📊 Obteniendo transacciones de cuenta:', accountId)

            const { data, error } = await supabase
                .from('transacciones')
                .select(`
                    *,
                    categorias!transacciones_categoria_id_fkey (
                        id,
                        nombre,
                        descripcion,
                        nombre_icono,
                        biblioteca_iconos,
                        grupo_id,
                        grupos_categoria!categorias_grupo_id_fkey (
                            id,
                            nombre,
                            color,
                            nombre_icono,
                            biblioteca_iconos
                        )
                    ),
                    niveles!transacciones_nivel_id_fkey (
                        id,
                        nombre,
                        color
                    )
                `)
                .eq('cuenta_id', accountId)
                .eq('usuario_id', user.id)
                .order('fecha_ocurrencia', { ascending: false })

            if (error) {
                console.error('💥 Error obteniendo transacciones:', error)
                throw error
            }

            accountTransactions.value = data || []
            console.log(`✅ ${data?.length || 0} transacciones obtenidas`)

            return data

        } catch (error) {
            console.error('💥 Error en fetchTransactionsByAccount:', error)

            if (toast) {
                toast.add({
                    severity: 'error',
                    summary: 'Error',
                    detail: error.message || 'Error al cargar las transacciones',
                    life: 5000
                })
            }

            accountTransactions.value = []
            throw error

        } finally {
            loading.value = false
        }
    }

    // FUNCIÓN PARA CREAR TRANSFERENCIA
    const createTransferencia = async (transferenciaData, { toast }) => {
        loading.value = true

        try {
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }

            console.log('💸 Creando transferencia:', transferenciaData)

            // 1. Obtener ambas cuentas
            const { data: cuentas, error: cuentasError } = await supabase
                .from('cuentas')
                .select('id, tipo, saldo, credito_disponible, limite_credito')
                .in('id', [transferenciaData.cuenta_origen_id, transferenciaData.cuenta_destino_id])

            if (cuentasError || !cuentas || cuentas.length !== 2) {
                throw new Error('Error al obtener información de las cuentas')
            }

            const cuentaOrigen = cuentas.find(c => c.id === transferenciaData.cuenta_origen_id)
            const cuentaDestino = cuentas.find(c => c.id === transferenciaData.cuenta_destino_id)

            const montoTransferencia = parseFloat(transferenciaData.monto)

            // 2. Validar saldo/crédito disponible en cuenta origen
            if (cuentaOrigen.tipo === 'credit_card') {
                if (parseFloat(cuentaOrigen.credito_disponible) < montoTransferencia) {
                    throw new Error('Crédito disponible insuficiente en cuenta origen')
                }
            } else {
                if (parseFloat(cuentaOrigen.saldo) < montoTransferencia) {
                    throw new Error('Saldo insuficiente en cuenta origen')
                }
            }

            // 3. Crear las transacciones
            const fechaOcurrencia = transferenciaData.fecha_ocurrencia

            // Transacción de SALIDA en cuenta origen (tipo transferencia)
            const transaccionSalida = {
                usuario_id: user.id,
                cuenta_id: transferenciaData.cuenta_origen_id,
                categoria_id: transferenciaData.categoria_id,
                nivel_id: null,
                tipo: 'transferencia',
                severidad: 'informacion',
                monto: montoTransferencia,
                fecha_ocurrencia: fechaOcurrencia,
                descripcion: transferenciaData.descripcion?.trim() || 'Transferencia enviada',
                url_recibo: null,
                metadatos: {
                    direccion: 'salida',
                    cuenta_relacionada_id: transferenciaData.cuenta_destino_id
                }
            }

            // Transacción de INGRESO en cuenta destino (tipo ingreso)
            const transaccionIngreso = {
                usuario_id: user.id,
                cuenta_id: transferenciaData.cuenta_destino_id,
                categoria_id: transferenciaData.categoria_id,
                nivel_id: null,
                tipo: 'ingreso',
                severidad: 'exito',
                monto: montoTransferencia,
                fecha_ocurrencia: fechaOcurrencia,
                descripcion: transferenciaData.descripcion?.trim() || 'Transferencia recibida',
                url_recibo: null,
                metadatos: {
                    origen: 'transferencia',
                    cuenta_relacionada_id: transferenciaData.cuenta_origen_id
                }
            }

            // Insertar ambas transacciones
            const { data: newTransactions, error: transactionError } = await supabase
                .from('transacciones')
                .insert([transaccionSalida, transaccionIngreso])
                .select('*')

            if (transactionError) {
                console.error('💥 Error creando transacciones:', transactionError)
                throw transactionError
            }

            console.log('✅ Transacciones de transferencia creadas:', newTransactions)

            // 4. Actualizar cuentas según el tipo
            let updateOrigen = {}
            let updateDestino = {}

            // CUENTA ORIGEN - Siempre se resta
            if (cuentaOrigen.tipo === 'credit_card') {
                // Tarjeta de crédito origen: aumenta crédito utilizado, disminuye crédito disponible
                const nuevoCredito = parseFloat(cuentaOrigen.credito_disponible) - montoTransferencia
                updateOrigen = {
                    credito_disponible: nuevoCredito,
                    fecha_actualizacion: new Date().toISOString()
                }
                console.log('💳 Cuenta origen (crédito) - Nuevo crédito disponible:', nuevoCredito)
            } else {
                // Cuenta normal origen: disminuye saldo
                const nuevoSaldo = parseFloat(cuentaOrigen.saldo) - montoTransferencia
                updateOrigen = {
                    saldo: nuevoSaldo,
                    fecha_actualizacion: new Date().toISOString()
                }
                console.log('🏦 Cuenta origen - Nuevo saldo:', nuevoSaldo)
            }

            // CUENTA DESTINO - Depende del tipo
            if (cuentaDestino.tipo === 'credit_card') {
                // Tarjeta de crédito destino: aumenta crédito disponible (pago a tarjeta)
                const nuevoCredito = parseFloat(cuentaDestino.credito_disponible) + montoTransferencia
                updateDestino = {
                    credito_disponible: nuevoCredito,
                    fecha_actualizacion: new Date().toISOString()
                }
                console.log('💳 Cuenta destino (crédito) - Nuevo crédito disponible:', nuevoCredito)
            } else {
                // Cuenta normal destino: aumenta saldo
                const nuevoSaldo = parseFloat(cuentaDestino.saldo) + montoTransferencia
                updateDestino = {
                    saldo: nuevoSaldo,
                    fecha_actualizacion: new Date().toISOString()
                }
                console.log('🏦 Cuenta destino - Nuevo saldo:', nuevoSaldo)
            }

            // Actualizar cuenta origen
            const { error: updateOrigenError } = await supabase
                .from('cuentas')
                .update(updateOrigen)
                .eq('id', transferenciaData.cuenta_origen_id)

            if (updateOrigenError) {
                console.error('💥 Error actualizando cuenta origen:', updateOrigenError)
                throw updateOrigenError
            }

            // Actualizar cuenta destino
            const { error: updateDestinoError } = await supabase
                .from('cuentas')
                .update(updateDestino)
                .eq('id', transferenciaData.cuenta_destino_id)

            if (updateDestinoError) {
                console.error('💥 Error actualizando cuenta destino:', updateDestinoError)
                throw updateDestinoError
            }

            console.log('✅ Cuentas actualizadas exitosamente')

            // Mostrar mensaje de éxito
            if (toast) {
                toast.add({
                    severity: 'success',
                    summary: 'Transferencia Realizada',
                    detail: `Se transfirieron $${montoTransferencia.toLocaleString('es-MX', { minimumFractionDigits: 2 })} exitosamente`,
                    life: 3000
                })
            }

            return newTransactions

        } catch (error) {
            console.error('💥 Error creando transferencia:', error)

            if (toast) {
                toast.add({
                    severity: 'error',
                    summary: 'Error',
                    detail: error.message || 'Error realizando la transferencia',
                    life: 5000
                })
            }

            throw error

        } finally {
            loading.value = false
        }
    }

    return {
        // Estados
        transactions,
        accountTransactions,
        loading,

        // Funciones
        createIngreso,
        createGasto,
        createTransferencia,
        fetchTransactionsByAccount
    }
})
