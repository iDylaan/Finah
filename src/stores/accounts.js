import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { supabase } from '@/lib/supabase.js'
import { handleError, diasHasta } from '@/lib/utils.js'
import { 
    calcularPeriodoActual, 
    porcentajeUsoCredito, 
    montoUsado,
    calcularPagoMinimo 
} from '@/lib/creditCardUtils.js'

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


            // Obtener cuentas con toda la información (solo activas)
            const { data: accountsData, error: accountsError } = await supabase
                .from('cuentas')
                .select('*')
                .eq('creada_por', user.id)
                .is('deleted_at', null) // Excluir cuentas eliminadas (soft delete)
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

            console.log('🗑️ Eliminando cuenta (soft delete):', accountId)

            // Soft delete: marcar deleted_at con la fecha actual
            const { error } = await supabase
                .from('cuentas')
                .update({ deleted_at: new Date().toISOString() })
                .eq('id', accountId)
                .eq('creada_por', user.id)
                .is('deleted_at', null) // Solo si no está ya eliminada

            if (error) {
                console.error('💥 Error eliminando cuenta:', error)
                throw error
            }

            // ✅ ACTUALIZAR ESTADO LOCAL DIRECTAMENTE (MÁS EFICIENTE)
            accounts.value = accounts.value.filter(account => account.id !== accountId)

            console.log('✅ Cuenta eliminada exitosamente (soft delete)')

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

    // ===== FUNCIONES PARA TARJETAS DE CRÉDITO =====

    /**
     * Obtiene transacciones de una cuenta en un periodo específico
     * @param {string} cuentaId - ID de la cuenta
     * @param {Date} fechaInicio - Fecha de inicio del periodo
     * @param {Date} fechaFin - Fecha de fin del periodo
     * @returns {Array} - Array de transacciones del periodo
     */
    const obtenerTransaccionesPeriodo = async (cuentaId, fechaInicio, fechaFin) => {
        try {
            const { data, error } = await supabase
                .from('transacciones')
                .select('*')
                .eq('cuenta_id', cuentaId)
                .is('deleted_at', null) // Excluir transacciones eliminadas
                .gte('fecha_ocurrencia', fechaInicio.toISOString().split('T')[0])
                .lte('fecha_ocurrencia', fechaFin.toISOString().split('T')[0])
                .order('fecha_ocurrencia', { ascending: false });

            if (error) throw error;

            return data || [];
        } catch (error) {
            console.error('Error obteniendo transacciones del periodo:', error);
            return [];
        }
    };

    /**
     * Calcula el total de gastos en el periodo actual de una tarjeta de crédito
     * @param {string} cuentaId - ID de la tarjeta de crédito
     * @param {number} diaCorte - Día del mes de corte
     * @returns {number} - Total de gastos del periodo
     */
    const calcularGastosPeriodoActual = async (cuentaId, diaCorte, diaPago) => {
        try {
            const { inicioCorte, finCorte } = calcularPeriodoActual(diaCorte, diaPago);
            
            console.log('📅 Periodo actual:', {
                inicioCorte: inicioCorte.toISOString().split('T')[0],
                finCorte: finCorte.toISOString().split('T')[0]
            });
            
            // Obtener transacciones normales del periodo
            const transacciones = await obtenerTransaccionesPeriodo(cuentaId, inicioCorte, finCorte);
            
            console.log('🧾 Transacciones del periodo:', transacciones);
            
            // Sumar solo gastos (tipo='gasto') del periodo
            const totalGastos = transacciones
                .filter(t => t.tipo === 'gasto')
                .reduce((sum, t) => sum + parseFloat(t.monto || 0), 0);
            
            console.log('💰 Gastos normales del periodo:', totalGastos);
            
            // Obtener cuotas MSI pendientes para este periodo
            const { data: cuotasMSI, error: msiError } = await supabase
                .from('ejecuciones_transacciones_periodicas')
                .select(`
                    id,
                    monto_programado,
                    fecha_programada,
                    estado,
                    numero_cuota,
                    transaccion_periodica:transacciones_periodicas!inner(
                        cuenta_id,
                        es_msi,
                        nombre
                    )
                `)
                .eq('transaccion_periodica.cuenta_id', cuentaId)
                .eq('transaccion_periodica.es_msi', true)
                .gte('fecha_programada', inicioCorte.toISOString().split('T')[0])
                .lte('fecha_programada', finCorte.toISOString().split('T')[0])
                .in('estado', ['pendiente', 'confirmada']) // Solo pendientes, NO las ya ejecutadas
            
            if (msiError) {
                console.error('Error obteniendo cuotas MSI:', msiError);
            }
            
            console.log('📋 Cuotas MSI del periodo:', cuotasMSI);
            
            // Sumar cuotas MSI del periodo
            const totalCuotasMSI = (cuotasMSI || [])
                .reduce((sum, cuota) => sum + parseFloat(cuota.monto_programado || 0), 0);
            
            console.log('💳 Total cuotas MSI:', totalCuotasMSI);
            console.log('🎯 TOTAL GASTOS DEL PERIODO:', totalGastos + totalCuotasMSI);
            
            return totalGastos + totalCuotasMSI;
        } catch (error) {
            console.error('Error calculando gastos del periodo:', error);
            return 0;
        }
    };

    /**
     * Obtiene información enriquecida de una tarjeta de crédito
     * @param {Object} tarjeta - Objeto de cuenta tipo credit_card
     * @returns {Object} - Información calculada de la tarjeta
     */
    const obtenerInfoTarjetaCredito = async (tarjeta) => {
        if (!tarjeta || tarjeta.tipo !== 'credit_card') return null;

        const { dia_corte, dia_pago, limite_credito, credito_disponible } = tarjeta;

        // Calcular periodo actual
        const periodo = calcularPeriodoActual(dia_corte, dia_pago);
        
        // Calcular días restantes
        const diasHastaCorte = diasHasta(periodo.finCorte);
        const diasHastaPago = diasHasta(periodo.proximoPago);
        
        // Calcular uso de crédito
        const porcentajeUso = porcentajeUsoCredito(limite_credito, credito_disponible);
        const montoUtilizado = montoUsado(limite_credito, credito_disponible);
        
        // Obtener gastos del periodo actual
        const gastosPeriodo = await calcularGastosPeriodoActual(
            tarjeta.id, 
            dia_corte, 
            dia_pago
        );
        
        // Calcular pago mínimo
        const pagoMinimo = calcularPagoMinimo(
            montoUtilizado, 
            tarjeta.porcentaje_pago_minimo || 5
        );

        return {
            // Información del periodo
            periodoInicio: periodo.inicioCorte,
            periodoFin: periodo.finCorte,
            proximoPago: periodo.proximoPago,
            
            // Días restantes
            diasHastaCorte,
            diasHastaPago,
            
            // Uso del crédito
            porcentajeUso,
            montoUtilizado,
            gastosPeriodo,
            
            // Información de pago
            pagoMinimo,
            pagoTotal: montoUtilizado,
            
            // Estado
            enPeligro: diasHastaPago <= 3 || porcentajeUso >= 90,
            requiereAtencion: diasHastaPago <= 7 || porcentajeUso >= 70
        };
    };

    /**
     * Computed: Tarjetas de crédito con información calculada
     */
    const tarjetasConInfo = computed(() => {
        return accounts.value
            .filter(acc => acc.tipo === 'credit_card')
            .map(tarjeta => ({
                ...tarjeta,
                // Se calculará de forma asíncrona cuando se necesite
                _needsInfoUpdate: true
            }));
    });

    /**
     * Obtiene el resumen completo de periodos de una tarjeta de crédito
     * @param {string} cuentaId - ID de la cuenta (tarjeta de crédito)
     * @returns {Object} - Resumen con periodo actual y siguiente
     */
    const obtenerResumenPeriodosTarjeta = async (cuentaId) => {
        try {
            const { data, error } = await supabase
                .rpc('obtener_resumen_periodos_tarjeta', {
                    p_cuenta_id: cuentaId
                });
            
            if (error) {
                console.error('Error obteniendo resumen de periodos:', error);
                throw error;
            }
            
            console.log('📊 Resumen de periodos:', data);
            return data;
        } catch (error) {
            console.error('Error en obtenerResumenPeriodosTarjeta:', error);
            throw error;
        }
    };

    /**
     * Procesa el corte de una tarjeta de crédito
     * Arrastra la deuda no pagada al siguiente periodo
     * @param {string} cuentaId - ID de la tarjeta de crédito
     * @returns {Object} - Resultado del proceso de corte
     */
    const procesarCorteTarjeta = async (cuentaId, { toast } = {}) => {
        try {
            const { data, error } = await supabase
                .rpc('procesar_corte_tarjeta', {
                    p_cuenta_id: cuentaId
                });
            
            if (error) {
                console.error('Error procesando corte de tarjeta:', error);
                handleError(error, { toast });
                throw error;
            }
            
            console.log('📅 Corte de tarjeta procesado:', data);
            
            if (data.procesado && toast) {
                toast.add({
                    severity: 'success',
                    summary: 'Corte Procesado',
                    detail: `Deuda de $${new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(data.saldo_arrastrado)} arrastrada al siguiente periodo`,
                    life: 4000
                });
            }
            
            // Refrescar cuentas
            await fetchAccountsWithDetails({ toast, force: true });
            
            return data;
        } catch (error) {
            console.error('Error en procesarCorteTarjeta:', error);
            throw error;
        }
    };

    /**
     * Registra un pago de periodo de tarjeta de crédito
     * Marca las cuotas MSI como pagadas y actualiza el crédito disponible
     * @param {Object} pagoData - Datos del pago
     * @param {string} pagoData.cuenta_tarjeta_id - ID de la tarjeta
     * @param {number} pagoData.monto_pago - Monto del pago
     * @param {string} pagoData.categoria_id - ID de la categoría
     * @param {Date|string} pagoData.fecha_pago - Fecha del pago
     * @param {string} pagoData.descripcion - Descripción opcional
     * @param {string} pagoData.tipo_pago - 'manual' o 'transfer'
     * @param {string} pagoData.cuenta_origen_id - ID de cuenta origen (si es transferencia)
     * @returns {string} - ID de la transacción creada
     */
    const registrarPagoPeriodoTarjeta = async (pagoData, { toast } = {}) => {
        try {
            const fecha = pagoData.fecha_pago instanceof Date
                ? pagoData.fecha_pago.toISOString().split('T')[0]
                : pagoData.fecha_pago;
            
            const params = {
                p_cuenta_tarjeta_id: pagoData.cuenta_tarjeta_id,
                p_monto_pago: pagoData.monto_pago,
                p_categoria_id: pagoData.categoria_id,
                p_fecha_pago: fecha,
                p_descripcion: pagoData.descripcion || null,
                p_tipo_pago: pagoData.tipo_pago || 'manual',
                p_cuenta_origen_id: pagoData.cuenta_origen_id || null
            };
            
            console.log('📤 Parámetros enviados a registrar_pago_periodo_tarjeta:', params);
            
            const { data, error } = await supabase
                .rpc('registrar_pago_periodo_tarjeta', params);
            
            if (error) {
                console.error('Error registrando pago de periodo:', error);
                handleError(error, { toast });
                throw error;
            }
            
            console.log('✅ Pago de periodo registrado:', data);
            
            if (toast) {
                toast.add({
                    severity: 'success',
                    summary: 'Pago Registrado',
                    detail: `Se registró el pago de ${new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(pagoData.monto_pago)}`,
                    life: 3000
                });
            }
            
            // Refrescar cuentas
            await fetchAccountsWithDetails({ toast, force: true });
            
            return data;
        } catch (error) {
            console.error('Error en registrarPagoPeriodoTarjeta:', error);
            throw error;
        }
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
        clearCache,

        // Funciones de tarjetas de crédito
        obtenerTransaccionesPeriodo,
        calcularGastosPeriodoActual,
        obtenerInfoTarjetaCredito,
        tarjetasConInfo,
        obtenerResumenPeriodosTarjeta,
        registrarPagoPeriodoTarjeta,
        procesarCorteTarjeta
    }
})