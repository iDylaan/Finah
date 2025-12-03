import { ref } from 'vue'
import { defineStore } from 'pinia'
import { supabase } from '@/lib/supabase.js'
import { handleError } from '@/lib/utils.js'

export const useAccountsStore = defineStore('accounts', () => {
    // Estados
    const accounts = ref([])
    const banks = ref([])
    const loading = ref(false)

    // ESTADOS PARA CACHÉ
    const accountsLoaded = ref(false)
    const banksLoaded = ref(false)
    const lastAccountsFetchTime = ref(null)
    const lastBanksFetchTime = ref(null)

    // Función para obtener bancos disponibles - CON CACHÉ
    const fetchBanks = async ({ toast, force = false } = {}) => {
        // Si ya tenemos datos y no es forzado, usar caché
        if (banksLoaded.value && banks.value.length > 0 && !force) {
            return banks.value;
        }

        loading.value = true

        try {
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }

            const { data, error } = await supabase
                .from('bancos')
                .select('*')
                .or(`es_publico.eq.true,usuario_id.eq.${user.id}`)
                .order('es_publico', { ascending: true })
                .order('nombre', { ascending: true })

            if (error) {
                console.error('💥 Error cargando bancos:', error)
                throw error
            }

            banks.value = data || []
            banksLoaded.value = true
            lastBanksFetchTime.value = Date.now()

            return banks.value

        } catch (error) {
            console.error('💥 Error en fetchBanks:', error)

            if (toast) {
                toast.add({
                    severity: 'error',
                    summary: 'Error',
                    detail: error.message || 'Error cargando bancos',
                    life: 5000
                })
            }

            throw error

        } finally {
            loading.value = false
        }
    }

    // Función para forzar reconsulta de bancos
    const refreshBanks = async ({ toast }) => {
        return await fetchBanks({ toast, force: true });
    };

    // Función para obtener cuentas con información relacionada - CON CACHÉ
    const fetchAccountsWithDetails = async ({ toast, force = false } = {}) => {
        // Si ya tenemos datos y no es forzado, usar caché
        if (accountsLoaded.value && accounts.value.length > 0 && !force) {
            return accounts.value;
        }

        loading.value = true

        try {
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }


            // Obtener cuentas con toda la información
            const { data: accountsData, error: accountsError } = await supabase
                .from('cuentas')
                .select('*')
                .eq('creada_por', user.id)
                .order('fecha_creacion', { ascending: false })

            if (accountsError) {
                console.error('💥 Error cargando cuentas:', accountsError)
                throw accountsError
            }

            console.log('📊 Cuentas de Supabase:', accountsData)

            // Obtener información de bancos para enriquecer los datos
            const bankIds = new Set()
            accountsData.forEach(account => {
                if (account.banco_id) {
                    bankIds.add(account.banco_id)
                }
            })

            let banksData = []
            if (bankIds.size > 0) {
                const { data: banksResult, error: banksError } = await supabase
                    .from('bancos')
                    .select('*')
                    .in('id', Array.from(bankIds))

                if (banksError) {
                    console.warn('⚠️ Error cargando información de bancos:', banksError)
                } else {
                    banksData = banksResult || []
                }
            }

            // Procesar y enriquecer datos
            const processedAccounts = accountsData.map(account => {
                const bank = banksData.find(b => b.id === account.banco_id) || null

                const processed = {
                    ...account,
                    banco: bank  // Agregar información completa del banco
                }

                // Log para tarjetas de crédito
                if (account.tipo === 'credit_card') {
                    console.log(`💳 Procesando tarjeta de crédito: ${account.nombre}`, {
                        banco: bank?.nombre,
                        limite: account.limite_credito,
                        credito_disponible: account.credito_disponible
                    })
                }

                return processed
            })

            accounts.value = processedAccounts
            accountsLoaded.value = true
            lastAccountsFetchTime.value = Date.now()
            console.log('✅ Cuentas cargadas:', accounts.value.length)
            console.log('💳 Tarjetas de crédito procesadas:', 
                accounts.value.filter(acc => acc.tipo === 'credit_card')
            )

            return accounts.value

        } catch (error) {
            console.error('💥 Error en fetchAccountsWithDetails:', error)

            if (toast) {
                toast.add({
                    severity: 'error',
                    summary: 'Error',
                    detail: error.message || 'Error cargando cuentas',
                    life: 5000
                })
            }

            throw error

        } finally {
            loading.value = false
        }
    }

    // Función para forzar reconsulta de cuentas
    const refreshAccounts = async ({ toast }) => {
        return await fetchAccountsWithDetails({ toast, force: true });
    };

    // Función para crear cuenta - ACTUALIZADA
    const createAccount = async (accountData, { toast }) => {
        loading.value = true

        try {
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }

            console.log('💳 Creando cuenta:', accountData)
            console.log('👤 Usuario autenticado:', user.id)

            // 1. Crear cuenta con todos los datos
            const accountInsert = {
                creada_por: user.id,
                grupo_usuario_id: accountData.grupo_usuario_id || null,
                banco_id: accountData.banco_id || null,
                nombre: accountData.nombre.trim(),
                tipo: accountData.tipo,
                saldo: Number(accountData.saldo) || 0,
                metadatos: { ...accountData.metadatos }
            }

            // Si es tarjeta de crédito, agregar campos específicos
            if (accountData.tipo === 'credit_card' && accountData.tarjeta_credito) {
                Object.assign(accountInsert, {
                    limite_credito: parseFloat(accountData.tarjeta_credito.limite_credito) || 0,
                    credito_disponible: parseFloat(accountData.tarjeta_credito.credito_disponible) || parseFloat(accountData.tarjeta_credito.limite_credito) || 0,
                    dia_pago: parseInt(accountData.tarjeta_credito.dia_pago) || 1,
                    dia_corte: parseInt(accountData.tarjeta_credito.dia_corte) || 1,
                    tasa_interes: accountData.tarjeta_credito.tasa_interes ? parseFloat(accountData.tarjeta_credito.tasa_interes) : null,
                    porcentaje_pago_minimo: accountData.tarjeta_credito.porcentaje_pago_minimo ? parseFloat(accountData.tarjeta_credito.porcentaje_pago_minimo) : null,
                    proxima_fecha_pago: accountData.tarjeta_credito.proxima_fecha_pago || null,
                    proxima_fecha_corte: accountData.tarjeta_credito.proxima_fecha_corte || null,
                    porcentaje_cat: accountData.tarjeta_credito.porcentaje_cat ? parseFloat(accountData.tarjeta_credito.porcentaje_cat) : null,
                    anualidad: parseFloat(accountData.tarjeta_credito.anualidad) || 0,
                    gasto_exencion_anualidad: accountData.tarjeta_credito.gasto_exencion_anualidad ? parseFloat(accountData.tarjeta_credito.gasto_exencion_anualidad) : null,
                    porcentaje_cashback: accountData.tarjeta_credito.porcentaje_cashback ? parseFloat(accountData.tarjeta_credito.porcentaje_cashback) : null,
                    puntos_por_peso: accountData.tarjeta_credito.puntos_por_peso ? parseFloat(accountData.tarjeta_credito.puntos_por_peso) : null,
                    dias_gracia: accountData.tarjeta_credito.dias_gracia ? parseInt(accountData.tarjeta_credito.dias_gracia) : null,
                    notas: accountData.tarjeta_credito.notas?.trim() || null
                })
            }

            console.log('🏦 Insertando cuenta:', accountInsert)

            const { data: newAccount, error: accountError } = await supabase
                .from('cuentas')
                .insert([accountInsert])
                .select('*')
                .single()

            if (accountError) {
                console.error('💥 Error creando cuenta:', accountError)
                throw accountError
            }

            console.log('✅ Cuenta creada:', newAccount)

            // 3. ✅ FORZAR RECARGA DE DATOS EN LUGAR DE SOLO RECARGAR
            await fetchAccountsWithDetails({ toast: null, force: true })

            // Mostrar mensaje de éxito
            if (toast) {
                toast.add({
                    severity: 'success',
                    summary: 'Cuenta Creada',
                    detail: `La cuenta "${accountData.nombre}" se creó exitosamente`,
                    life: 3000
                })
            }

            return newAccount

        } catch (error) {
            console.error('💥 Error creando cuenta:', error)

            if (toast) {
                toast.add({
                    severity: 'error',
                    summary: 'Error',
                    detail: error.message || 'Error creando la cuenta',
                    life: 5000
                })
            }

            throw error

        } finally {
            loading.value = false
        }
    }

    // Función para actualizar cuenta - ACTUALIZADA
    const updateAccount = async (accountId, accountData, { toast }) => {
        loading.value = true

        try {
            console.log('📝 Actualizando cuenta:', accountId, accountData)

            // 1. Actualizar cuenta con todos los datos
            const accountUpdate = {
                banco_id: accountData.banco_id || null,
                nombre: accountData.nombre.trim(),
                tipo: accountData.tipo,
                saldo: Number(accountData.saldo) || 0,
                metadatos: { ...accountData.metadatos },
                fecha_actualizacion: new Date().toISOString()
            }

            // Si es tarjeta de crédito, incluir campos específicos
            if (accountData.tipo === 'credit_card' && accountData.tarjeta_credito) {
                Object.assign(accountUpdate, {
                    limite_credito: parseFloat(accountData.tarjeta_credito.limite_credito) || 0,
                    credito_disponible: parseFloat(accountData.tarjeta_credito.credito_disponible) || parseFloat(accountData.tarjeta_credito.limite_credito) || 0,
                    dia_pago: parseInt(accountData.tarjeta_credito.dia_pago) || 1,
                    dia_corte: parseInt(accountData.tarjeta_credito.dia_corte) || 1,
                    tasa_interes: accountData.tarjeta_credito.tasa_interes ? parseFloat(accountData.tarjeta_credito.tasa_interes) : null,
                    porcentaje_pago_minimo: accountData.tarjeta_credito.porcentaje_pago_minimo ? parseFloat(accountData.tarjeta_credito.porcentaje_pago_minimo) : null,
                    proxima_fecha_pago: accountData.tarjeta_credito.proxima_fecha_pago || null,
                    proxima_fecha_corte: accountData.tarjeta_credito.proxima_fecha_corte || null,
                    porcentaje_cat: accountData.tarjeta_credito.porcentaje_cat ? parseFloat(accountData.tarjeta_credito.porcentaje_cat) : null,
                    anualidad: parseFloat(accountData.tarjeta_credito.anualidad) || 0,
                    gasto_exencion_anualidad: accountData.tarjeta_credito.gasto_exencion_anualidad ? parseFloat(accountData.tarjeta_credito.gasto_exencion_anualidad) : null,
                    porcentaje_cashback: accountData.tarjeta_credito.porcentaje_cashback ? parseFloat(accountData.tarjeta_credito.porcentaje_cashback) : null,
                    puntos_por_peso: accountData.tarjeta_credito.puntos_por_peso ? parseFloat(accountData.tarjeta_credito.puntos_por_peso) : null,
                    dias_gracia: accountData.tarjeta_credito.dias_gracia ? parseInt(accountData.tarjeta_credito.dias_gracia) : null,
                    notas: accountData.tarjeta_credito.notas?.trim() || null
                })
            } else {
                // Si cambió de credit_card a otro tipo, limpiar campos de tarjeta
                Object.assign(accountUpdate, {
                    limite_credito: null,
                    credito_disponible: null,
                    dia_pago: null,
                    dia_corte: null,
                    tasa_interes: null,
                    porcentaje_pago_minimo: null,
                    proxima_fecha_pago: null,
                    proxima_fecha_corte: null,
                    porcentaje_cat: null,
                    anualidad: null,
                    gasto_exencion_anualidad: null,
                    porcentaje_cashback: null,
                    puntos_por_peso: null,
                    dias_gracia: null,
                    notas: null
                })
            }

            console.log('🔄 Datos para actualizar cuenta:', accountUpdate)

            const { data: updatedAccount, error: accountError } = await supabase
                .from('cuentas')
                .update(accountUpdate)
                .eq('id', accountId)
                .select('*')
                .single()

            if (accountError) {
                console.error('💥 Error actualizando cuenta:', accountError)
                throw accountError
            }

            console.log('✅ Cuenta actualizada:', updatedAccount)

            // 2. ✅ FORZAR RECARGA DE DATOS
            await fetchAccountsWithDetails({ toast: null, force: true })

            // Mostrar mensaje de éxito
            if (toast) {
                toast.add({
                    severity: 'success',
                    summary: 'Cuenta Actualizada',
                    detail: `La cuenta "${accountData.name}" se actualizó exitosamente`,
                    life: 3000
                })
            }

            return updatedAccount

        } catch (error) {
            console.error('💥 Error actualizando cuenta:', error)

            if (toast) {
                toast.add({
                    severity: 'error',
                    summary: 'Error',
                    detail: error.message || 'Error actualizando la cuenta',
                    life: 5000
                })
            }

            throw error

        } finally {
            loading.value = false
        }
    }

    // Función para eliminar cuenta - ACTUALIZADA
    const deleteAccount = async (accountId, { toast }) => {
        loading.value = true

        try {
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }

            console.log('🗑️ Eliminando cuenta:', accountId)

            // Eliminar account (CASCADE eliminará credit_cards automáticamente)
            const { error } = await supabase
                .from('cuentas')
                .delete()
                .eq('id', accountId)
                .eq('creada_por', user.id)

            if (error) {
                console.error('💥 Error eliminando cuenta:', error)
                throw error
            }

            // ✅ ACTUALIZAR ESTADO LOCAL DIRECTAMENTE (MÁS EFICIENTE)
            accounts.value = accounts.value.filter(account => account.id !== accountId)

            console.log('✅ Cuenta eliminada exitosamente')

            // Mostrar mensaje de éxito
            if (toast) {
                toast.add({
                    severity: 'success',
                    summary: 'Cuenta Eliminada',
                    detail: 'La cuenta ha sido eliminada exitosamente',
                    life: 3000
                })
            }

            return true

        } catch (error) {
            console.error('💥 Error eliminando cuenta:', error)

            if (toast) {
                toast.add({
                    severity: 'error',
                    summary: 'Error',
                    detail: error.message || 'Error eliminando la cuenta',
                    life: 5000
                })
            }

            throw error

        } finally {
            loading.value = false
        }
    }

    // ✅ FUNCIÓN PARA LIMPIAR CACHÉ
    const clearCache = () => {
        accounts.value = [];
        banks.value = [];
        accountsLoaded.value = false;
        banksLoaded.value = false;
        lastAccountsFetchTime.value = null;
        lastBanksFetchTime.value = null;
        console.log('🧹 Caché de cuentas limpiado');
    };

    return {
        // Estados
        accounts,
        banks,
        loading,
        accountsLoaded,
        banksLoaded,
        lastAccountsFetchTime,
        lastBanksFetchTime,

        // Funciones
        fetchBanks,
        refreshBanks,
        fetchAccountsWithDetails,
        refreshAccounts,
        createAccount,
        updateAccount,
        deleteAccount,
        clearCache
    }
})