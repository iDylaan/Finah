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


            // Obtener cuentas básicas
            const { data: accountsData, error: accountsError } = await supabase
                .from('cuentas')
                .select(`
                    *,
                    tarjetas_credito (
                        banco_id,
                        nombre_tarjeta,
                        ultimos_cuatro_digitos,
                        limite_credito,
                        credito_disponible,
                        dia_pago,
                        dia_corte,
                        tasa_interes,
                        porcentaje_pago_minimo,
                        proxima_fecha_pago,
                        proxima_fecha_corte,
                        porcentaje_cat,
                        anualidad,
                        gasto_exencion_anualidad,
                        porcentaje_cashback,
                        puntos_por_peso,
                        dias_gracia,
                        notas,
                        fecha_creacion,
                        fecha_actualizacion
                    )
                `)
                .eq('creada_por', user.id)
                .order('fecha_creacion', { ascending: false })

            if (accountsError) {
                console.error('💥 Error cargando cuentas:', accountsError)
                throw accountsError
            }

            // Obtener información de bancos para enriquecer los datos
            const bankIds = new Set()
            accountsData.forEach(account => {
                if (account.metadatos?.banco_id) {
                    bankIds.add(account.metadatos.banco_id)
                }
                if (account.tarjetas_credito?.[0]?.banco_id) {
                    bankIds.add(account.tarjetas_credito[0].banco_id)
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
                const bankId = account.metadatos?.banco_id || account.tarjetas_credito?.[0]?.banco_id
                const bank = banksData.find(b => b.id === bankId) || null

                return {
                    ...account,
                    bank: bank,
                    credit_card: account.tarjetas_credito?.[0] || null,
                    // Limpiar el array anidado ya que lo movimos a credit_card
                    tarjetas_credito: undefined
                }
            })

            accounts.value = processedAccounts
            accountsLoaded.value = true
            lastAccountsFetchTime.value = Date.now()
            console.log('✅ Cuentas cargadas:', accounts.value.length)

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

            // 1. Crear cuenta principal
            const accountInsert = {
                creada_por: user.id,
                grupo_usuario_id: accountData.user_group_id || null,
                nombre: accountData.name.trim(),
                tipo: accountData.type,
                saldo: Number(accountData.balance) || 0,
                metadatos: {}
            }

            // Agregar metadata según el tipo
            if (accountData.account_number) {
                accountInsert.metadatos.numero_cuenta = accountData.account_number
            }

            if (accountData.last_four_digits) {
                accountInsert.metadatos.ultimos4 = accountData.last_four_digits
            }

            console.log('🏦 Insertando cuenta:', accountInsert)

            // const { data: newAccount, error: accountError } = await supabase
            //     .from('cuentas')
            //     .insert([accountInsert])
            //     .select('*')
            //     .single()

            if (accountError) {
                console.error('💥 Error creando cuenta:', accountError)
                throw accountError
            }

            console.log('✅ Cuenta creada:', newAccount)

            // 2. Si es tarjeta de crédito, crear registro en tarjetas_credito
            if (accountData.type === 'credit_card') {
                const creditCardInsert = {
                    cuenta_id: newAccount.id,
                    banco_id: accountData.bank_id,
                    nombre_tarjeta: accountData.card_name || accountData.name,
                    ultimos_cuatro_digitos: accountData.last_four_digits || null,
                    limite_credito: accountData.credit_limit || 0,
                    credito_disponible: accountData.available_credit || accountData.credit_limit || 0,
                    dia_pago: accountData.payment_day || 1,
                    dia_corte: accountData.cutoff_day || 1,
                    tasa_interes: accountData.interest_rate || null,
                    porcentaje_pago_minimo: accountData.min_payment_percent || 5,
                    proxima_fecha_pago: accountData.next_payment_date || null,
                    proxima_fecha_corte: accountData.next_cutoff_date || null,
                    porcentaje_cat: accountData.cat_percentage || null,
                    anualidad: accountData.annual_fee !== undefined ? Number(accountData.annual_fee) : 0,
                    gasto_exencion_anualidad: accountData.annual_fee_waiver_spending || null,
                    porcentaje_cashback: accountData.cashback_percentage || null,
                    puntos_por_peso: accountData.rewards_points_ratio || null,
                    dias_gracia: accountData.grace_period_days || null,
                    notas: accountData.notes?.trim() || null
                }

                console.log('🃏 Insertando tarjeta_credito:', creditCardInsert);
                console.log('🔍 Datos originales recibidos:', {
                    cat_percentage: accountData.cat_percentage,
                    annual_fee: accountData.annual_fee,
                    annual_fee_waiver_spending: accountData.annual_fee_waiver_spending,
                    cashback_percentage: accountData.cashback_percentage,
                    rewards_points_ratio: accountData.rewards_points_ratio,
                    grace_period_days: accountData.grace_period_days,
                    notes: accountData.notes
                });

                // const { error: creditError } = await supabase
                //     .from('tarjetas_credito')
                //     .insert([creditCardInsert])

                // if (creditError) {
                //     console.error('💥 Error creando tarjeta_credito:', creditError)
                //     console.error('💥 Datos que causaron el error:', creditCardInsert)
                //     // Limpiar account creado
                //     await supabase.from('cuentas').delete().eq('id', newAccount.id)
                //     throw creditError
                // }

                console.log('✅ Tarjeta de crédito creada para cuenta:', newAccount.id)
            }

            // 3. ✅ FORZAR RECARGA DE DATOS EN LUGAR DE SOLO RECARGAR
            await fetchAccountsWithDetails({ toast: null, force: true })

            // Mostrar mensaje de éxito
            if (toast) {
                toast.add({
                    severity: 'success',
                    summary: 'Cuenta Creada',
                    detail: `La cuenta "${accountData.name}" se creó exitosamente`,
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

            // 1. Actualizar cuenta principal
            const accountUpdate = {
                nombre: accountData.name.trim(),
                tipo: accountData.type,
                saldo: Number(accountData.balance) || 0,
                metadatos: {},
                fecha_actualizacion: new Date().toISOString()
            }

            // Agregar metadata
            if (accountData.account_number) {
                accountUpdate.metadatos.numero_cuenta = accountData.account_number
            }

            if (accountData.last_four_digits) {
                accountUpdate.metadatos.ultimos4 = accountData.last_four_digits
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

            // 2. Si es tarjeta de crédito, actualizar o crear registro en tarjetas_credito
            if (accountData.type === 'credit_card') {
                const creditCardData = {
                    banco_id: accountData.bank_id,
                    nombre_tarjeta: accountData.card_name || accountData.name,
                    ultimos_cuatro_digitos: accountData.last_four_digits,
                    limite_credito: accountData.credit_limit || 0,
                    credito_disponible: accountData.available_credit || accountData.credit_limit || 0,
                    dia_pago: accountData.payment_day || 1,
                    dia_corte: accountData.cutoff_day || 1,
                    tasa_interes: accountData.interest_rate || null,
                    porcentaje_pago_minimo: accountData.min_payment_percent || 5,
                    proxima_fecha_pago: accountData.next_payment_date || null,
                    proxima_fecha_corte: accountData.next_cutoff_date || null,
                    porcentaje_cat: accountData.cat_percentage || null,
                    anualidad: accountData.annual_fee !== undefined ? accountData.annual_fee : 0,
                    gasto_exencion_anualidad: accountData.annual_fee_waiver_spending || null,
                    porcentaje_cashback: accountData.cashback_percentage || null,
                    puntos_por_peso: accountData.rewards_points_ratio || null,
                    dias_gracia: accountData.grace_period_days || null,
                    notas: accountData.notes?.trim() || null
                }

                console.log('🔄 Datos tarjeta_credito para actualizar:', creditCardData);
                console.log('🔍 Datos originales para update recibidos:', {
                    cat_percentage: accountData.cat_percentage,
                    annual_fee: accountData.annual_fee,
                    annual_fee_waiver_spending: accountData.annual_fee_waiver_spending,
                    cashback_percentage: accountData.cashback_percentage,
                    rewards_points_ratio: accountData.rewards_points_ratio,
                    grace_period_days: accountData.grace_period_days,
                    notes: accountData.notes
                });

                // Verificar si ya existe registro en tarjetas_credito
                const { data: existingCard } = await supabase
                    .from('tarjetas_credito')
                    .select('cuenta_id')
                    .eq('cuenta_id', accountId)
                    .single()

                if (existingCard) {
                    // Actualizar existente
                    console.log('🔄 Actualizando tarjeta_credito existente');
                    const { error: creditError } = await supabase
                        .from('tarjetas_credito')
                        .update(creditCardData)
                        .eq('cuenta_id', accountId)

                    if (creditError) {
                        console.error('💥 Error actualizando tarjeta_credito:', creditError)
                        throw creditError
                    }
                } else {
                    // Crear nuevo
                    console.log('🆕 Creando nueva tarjeta_credito');
                    const { error: creditError } = await supabase
                        .from('tarjetas_credito')
                        .insert([{ cuenta_id: accountId, ...creditCardData }])

                    if (creditError) {
                        console.error('💥 Error creando tarjeta_credito:', creditError)
                        throw creditError
                    }
                }

                console.log('✅ Tarjeta de crédito actualizada para cuenta:', accountId)
            } else {
                // Si cambió de tipo y ya no es credit_card, eliminar registro
                await supabase
                    .from('tarjetas_credito')
                    .delete()
                    .eq('cuenta_id', accountId)
            }

            // 3. ✅ FORZAR RECARGA DE DATOS
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