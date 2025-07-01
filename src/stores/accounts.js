import { ref } from 'vue'
import { defineStore } from 'pinia'
import { supabase } from '@/lib/supabase.js'
import { handleError } from '@/lib/utils.js'

export const useAccountsStore = defineStore('accounts', () => {
    // Estados
    const accounts = ref([])
    const banks = ref([])
    const loading = ref(false)
    
    // ✅ NUEVOS ESTADOS PARA CACHÉ
    const accountsLoaded = ref(false)
    const banksLoaded = ref(false)
    const lastAccountsFetchTime = ref(null)
    const lastBanksFetchTime = ref(null)

    // Función para obtener bancos disponibles - CON CACHÉ
    const fetchBanks = async ({ toast, force = false } = {}) => {
        // Si ya tenemos datos y no es forzado, usar caché
        if (banksLoaded.value && banks.value.length > 0 && !force) {
            console.log('🔄 Usando datos de bancos en caché');
            return banks.value;
        }
        
        loading.value = true
        
        try {
            const { data: { user }, error: userError } = await supabase.auth.getUser()
            
            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }
            
            console.log('🏦 Consultando bancos desde la base de datos...')
            
            const { data, error } = await supabase
                .from('banks')
                .select('*')
                .or(`is_public.eq.true,user_id.eq.${user.id}`)
                .order('is_public', { ascending: true })
                .order('name', { ascending: true })
            
            if (error) {
                console.error('💥 Error cargando bancos:', error)
                throw error
            }
            
            banks.value = data || []
            banksLoaded.value = true
            lastBanksFetchTime.value = Date.now()
            console.log('✅ Bancos cargados:', banks.value.length)
            
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
            console.log('🔄 Usando datos de cuentas en caché');
            return accounts.value;
        }
        
        loading.value = true
        
        try {
            const { data: { user }, error: userError } = await supabase.auth.getUser()
            
            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }
            
            console.log('💳 Consultando cuentas desde la base de datos...')
            
            // Obtener cuentas básicas
            const { data: accountsData, error: accountsError } = await supabase
                .from('accounts')
                .select(`
                    *,
                    credit_cards (
                        bank_id,
                        card_name,
                        last_four_digits,
                        credit_limit,
                        available_credit,
                        payment_day,
                        cutoff_day,
                        interest_rate,
                        min_payment_percent,
                        next_payment_date,
                        next_cutoff_date,
                        cat_percentage,
                        annual_fee,
                        annual_fee_waiver_spending,
                        cashback_percentage,
                        rewards_points_ratio,
                        grace_period_days,
                        notes,
                        created_at,
                        updated_at
                    )
                `)
                .eq('created_by', user.id)
                .order('created_at', { ascending: false })
            
            if (accountsError) {
                console.error('💥 Error cargando cuentas:', accountsError)
                throw accountsError
            }
            
            // Obtener información de bancos para enriquecer los datos
            const bankIds = new Set()
            accountsData.forEach(account => {
                if (account.metadata?.bank_id) {
                    bankIds.add(account.metadata.bank_id)
                }
                if (account.credit_cards?.[0]?.bank_id) {
                    bankIds.add(account.credit_cards[0].bank_id)
                }
            })
            
            let banksData = []
            if (bankIds.size > 0) {
                const { data: banksResult, error: banksError } = await supabase
                    .from('banks')
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
                const bankId = account.metadata?.bank_id || account.credit_cards?.[0]?.bank_id
                const bank = banksData.find(b => b.id === bankId) || null
                
                return {
                    ...account,
                    bank: bank,
                    credit_card: account.credit_cards?.[0] || null,
                    // Limpiar el array anidado ya que lo movimos a credit_card
                    credit_cards: undefined
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
                created_by: user.id,
                user_group_id: accountData.user_group_id || null,
                name: accountData.name.trim(),
                type: accountData.type,
                balance: Number(accountData.balance) || 0,
                metadata: {}
            }
            
            // Agregar metadata según el tipo
            if (accountData.account_number) {
                accountInsert.metadata.account_number = accountData.account_number
            }
            
            if (accountData.last_four_digits) {
                accountInsert.metadata.last4 = accountData.last_four_digits
            }
            
            console.log('🏦 Insertando cuenta:', accountInsert)
            
            const { data: newAccount, error: accountError } = await supabase
                .from('accounts')
                .insert([accountInsert])
                .select('*')
                .single()
            
            if (accountError) {
                console.error('💥 Error creando cuenta:', accountError)
                throw accountError
            }
            
            console.log('✅ Cuenta creada:', newAccount)
            
            // 2. Si es tarjeta de crédito, crear registro en credit_cards
            if (accountData.type === 'credit_card') {
                const creditCardInsert = {
                    account_id: newAccount.id,
                    bank_id: accountData.bank_id,
                    card_name: accountData.card_name || accountData.name,
                    last_four_digits: accountData.last_four_digits || null,
                    credit_limit: accountData.credit_limit || 0,
                    available_credit: accountData.available_credit || accountData.credit_limit || 0,
                    payment_day: accountData.payment_day || 1,
                    cutoff_day: accountData.cutoff_day || 1,
                    interest_rate: accountData.interest_rate || null,
                    min_payment_percent: accountData.min_payment_percent || 5,
                    next_payment_date: accountData.next_payment_date || null,
                    next_cutoff_date: accountData.next_cutoff_date || null,
                    cat_percentage: accountData.cat_percentage || null,
                    annual_fee: accountData.annual_fee !== undefined ? Number(accountData.annual_fee) : 0,
                    annual_fee_waiver_spending: accountData.annual_fee_waiver_spending || null,
                    cashback_percentage: accountData.cashback_percentage || null,
                    rewards_points_ratio: accountData.rewards_points_ratio || null,
                    grace_period_days: accountData.grace_period_days || null,
                    notes: accountData.notes?.trim() || null
                }
                
                console.log('🃏 Insertando credit_card:', creditCardInsert);
                console.log('🔍 Datos originales recibidos:', {
                    cat_percentage: accountData.cat_percentage,
                    annual_fee: accountData.annual_fee,
                    annual_fee_waiver_spending: accountData.annual_fee_waiver_spending,
                    cashback_percentage: accountData.cashback_percentage,
                    rewards_points_ratio: accountData.rewards_points_ratio,
                    grace_period_days: accountData.grace_period_days,
                    notes: accountData.notes
                });
                
                const { error: creditError } = await supabase
                    .from('credit_cards')
                    .insert([creditCardInsert])
                
                if (creditError) {
                    console.error('💥 Error creando credit_card:', creditError)
                    console.error('💥 Datos que causaron el error:', creditCardInsert)
                    // Limpiar account creado
                    await supabase.from('accounts').delete().eq('id', newAccount.id)
                    throw creditError
                }
                
                console.log('✅ Credit card creado para account:', newAccount.id)
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
                name: accountData.name.trim(),
                type: accountData.type,
                balance: Number(accountData.balance) || 0,
                metadata: {},
                updated_at: new Date().toISOString()
            }
            
            // Agregar metadata
            if (accountData.account_number) {
                accountUpdate.metadata.account_number = accountData.account_number
            }
            
            if (accountData.last_four_digits) {
                accountUpdate.metadata.last4 = accountData.last_four_digits
            }
            
            console.log('🔄 Datos para actualizar cuenta:', accountUpdate)
            
            const { data: updatedAccount, error: accountError } = await supabase
                .from('accounts')
                .update(accountUpdate)
                .eq('id', accountId)
                .select('*')
                .single()
            
            if (accountError) {
                console.error('💥 Error actualizando cuenta:', accountError)
                throw accountError
            }
            
            console.log('✅ Cuenta actualizada:', updatedAccount)
            
            // 2. Si es tarjeta de crédito, actualizar o crear registro en credit_cards
            if (accountData.type === 'credit_card') {
                const creditCardData = {
                    bank_id: accountData.bank_id,
                    card_name: accountData.card_name || accountData.name,
                    last_four_digits: accountData.last_four_digits,
                    credit_limit: accountData.credit_limit || 0,
                    available_credit: accountData.available_credit || accountData.credit_limit || 0,
                    payment_day: accountData.payment_day || 1,
                    cutoff_day: accountData.cutoff_day || 1,
                    interest_rate: accountData.interest_rate || null,
                    min_payment_percent: accountData.min_payment_percent || 5,
                    next_payment_date: accountData.next_payment_date || null,
                    next_cutoff_date: accountData.next_cutoff_date || null,
                    cat_percentage: accountData.cat_percentage || null,
                    annual_fee: accountData.annual_fee !== undefined ? accountData.annual_fee : 0,
                    annual_fee_waiver_spending: accountData.annual_fee_waiver_spending || null,
                    cashback_percentage: accountData.cashback_percentage || null,
                    rewards_points_ratio: accountData.rewards_points_ratio || null,
                    grace_period_days: accountData.grace_period_days || null,
                    notes: accountData.notes?.trim() || null
                }
                
                console.log('🔄 Datos credit_card para actualizar:', creditCardData);
                console.log('🔍 Datos originales para update recibidos:', {
                    cat_percentage: accountData.cat_percentage,
                    annual_fee: accountData.annual_fee,
                    annual_fee_waiver_spending: accountData.annual_fee_waiver_spending,
                    cashback_percentage: accountData.cashback_percentage,
                    rewards_points_ratio: accountData.rewards_points_ratio,
                    grace_period_days: accountData.grace_period_days,
                    notes: accountData.notes
                });
                
                // Verificar si ya existe registro en credit_cards
                const { data: existingCard } = await supabase
                    .from('credit_cards')
                    .select('account_id')
                    .eq('account_id', accountId)
                    .single()
                
                if (existingCard) {
                    // Actualizar existente
                    console.log('🔄 Actualizando credit_card existente');
                    const { error: creditError } = await supabase
                        .from('credit_cards')
                        .update(creditCardData)
                        .eq('account_id', accountId)
                    
                    if (creditError) {
                        console.error('💥 Error actualizando credit_card:', creditError)
                        throw creditError
                    }
                } else {
                    // Crear nuevo
                    console.log('🆕 Creando nuevo credit_card');
                    const { error: creditError } = await supabase
                        .from('credit_cards')
                        .insert([{ account_id: accountId, ...creditCardData }])
                    
                    if (creditError) {
                        console.error('💥 Error creando credit_card:', creditError)
                        throw creditError
                    }
                }
                
                console.log('✅ Credit card actualizado para account:', accountId)
            } else {
                // Si cambió de tipo y ya no es credit_card, eliminar registro
                await supabase
                    .from('credit_cards')
                    .delete()
                    .eq('account_id', accountId)
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
                .from('accounts')
                .delete()
                .eq('id', accountId)
                .eq('created_by', user.id)
            
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