import { ref, computed } from 'vue';
import { ACCOUNT_TYPES } from '@/assets/constants/account-types';

export function useAccountForm() {
    // Estado del formulario
    const accountForm = ref({
        type: 'cash',
        banco_id: null,
        name: '',
        account_number: '',
        last_four_digits: '',
        balance: 0,
        card_name: '',
        limite_credito: 0,
        credito_disponible: 0,
        dia_pago: 1,
        dia_corte: 1,
        tasa_interes: null,
        porcentaje_pago_minimo: 5,
        porcentaje_cat: null,
        anualidad: 0,
        gasto_exencion_anualidad: null,
        porcentaje_cashback: null,
        ratio_puntos_recompensa: null,
        dias_periodo_gracia: null,
        notas: ''
    });

    const formErrors = ref({});
    const isSubmitting = ref(false);
    const isLoadingAccountData = ref(false);
    const loadedAccountData = ref(null);

    // Computed properties
    const needsBankSelection = computed(() => {
        return ['bank', 'debit_card', 'credit_card'].includes(accountForm.value.type);
    });

    const showCardFields = computed(() => {
        return ['debit_card', 'credit_card'].includes(accountForm.value.type);
    });

    const isCreditCard = computed(() => {
        return accountForm.value.type === 'credit_card';
    });

    // Funciones
    const resetForm = () => {
        console.log('🔄 Reseteando formulario');
        
        accountForm.value = {
            type: 'cash',
            banco_id: null,
            name: '',
            account_number: '',
            last_four_digits: '',
            balance: 0,
            card_name: '',
            limite_credito: 0,
            credito_disponible: 0,
            dia_pago: 1,
            dia_corte: 1,
            tasa_interes: null,
            porcentaje_pago_minimo: 5,
            porcentaje_cat: null,
            anualidad: 0,
            gasto_exencion_anualidad: null,
            porcentaje_cashback: null,
            ratio_puntos_recompensa: null,
            dias_periodo_gracia: null,
            notas: ''
        };

        formErrors.value = {};
        loadedAccountData.value = null;
    };

    const selectAccountType = (type) => {
        console.log('🔄 Cambiando tipo de cuenta a:', type);
        
        // Limpiar errores
        formErrors.value = {};
        accountForm.value.type = type;

        // Limpiar campos según el tipo
        if (type !== 'credit_card') {
            // Limpiar campos de tarjeta de crédito
            Object.assign(accountForm.value, {
                card_name: '',
                limite_credito: 0,
                credito_disponible: 0,
                dia_pago: 1,
                dia_corte: 1,
                tasa_interes: null,
                porcentaje_cat: null,
                anualidad: 0,
                gasto_exencion_anualidad: null,
                porcentaje_cashback: null,
                ratio_puntos_recompensa: null,
                dias_periodo_gracia: null,
                notas: ''
            });
        }

        // Limpiar últimos 4 dígitos si no es tarjeta
        if (!['debit_card', 'credit_card'].includes(type)) {
            accountForm.value.last_four_digits = '';
        }

        // Limpiar selección de banco si no es necesario
        if (!['bank', 'debit_card', 'credit_card'].includes(type)) {
            accountForm.value.banco_id = null;
        }

        if (type === 'credit_card') {
            accountForm.value.balance = 0; // Las tarjetas de crédito no tienen saldo inicial
        }
    };

    const getNamePlaceholder = () => {
        const placeholders = {
            'cash': 'Ej: Efectivo en cartera',
            'bank': 'Ej: Cuenta de ahorros BBVA',
            'debit_card': 'Ej: Tarjeta de débito Santander',
            'credit_card': 'Ej: Tarjeta BBVA Oro'
        };
        return placeholders[accountForm.value.type] || 'Ej: Mi cuenta';
    };

    const loadAccountForEdit = (account) => {
        console.log('📥 Cargando cuenta para editar:', account);
        console.log('📥 Credit card data:', account.credit_card);

        loadedAccountData.value = account;

        // Cargar datos en el formulario
        accountForm.value = {
            type: account.type || 'cash',
            banco_id: account.metadatos?.banco_id || account.tarjeta_credito?.banco_id || null,
            name: account.nombre || '',
            account_number: account.metadatos?.numero_cuenta || '',
            last_four_digits: account.metadatos?.ultimos_4_digitos || account.tarjeta_credito?.ultimos_4_digitos || '',
            balance: account.saldo || 0,
            
            // Campos BÁSICOS de tarjeta de crédito
            card_name: account.tarjeta_credito?.nombre_tarjeta || '',
            limite_credito: account.tarjeta_credito?.limite_credito || 0,
            credito_disponible: account.tarjeta_credito?.credito_disponible || 0,
            dia_pago: account.tarjeta_credito?.dia_pago || 1,
            dia_corte: account.tarjeta_credito?.dia_corte || 1,
            tasa_interes: account.tarjeta_credito?.tasa_interes || null,
            porcentaje_pago_minimo: account.tarjeta_credito?.porcentaje_pago_minimo || 5,
            
            // Campos OPCIONALES de tarjeta de crédito
            porcentaje_cat: account.tarjeta_credito?.porcentaje_cat || null,
            anualidad: account.tarjeta_credito?.anualidad || 0,
            gasto_exencion_anualidad: account.tarjeta_credito?.gasto_exencion_anualidad || null,
            porcentaje_cashback: account.tarjeta_credito?.porcentaje_cashback || null,
            ratio_puntos_recompensa: account.tarjeta_credito?.ratio_puntos_recompensa || null,
            dias_periodo_gracia: account.tarjeta_credito?.dias_periodo_gracia || null,
            notas: account.tarjeta_credito?.notas || ''
        };

        console.log('📝 Formulario cargado con datos:', accountForm.value);
        console.log('📝 Campos de tarjeta específicos:', {
            porcentaje_cat: accountForm.value.porcentaje_cat,
            anualidad: accountForm.value.anualidad,
            gasto_exencion_anualidad: accountForm.value.gasto_exencion_anualidad,
            porcentaje_cashback: accountForm.value.porcentaje_cashback,
            ratio_puntos_recompensa: accountForm.value.ratio_puntos_recompensa,
            dias_periodo_gracia: accountForm.value.dias_periodo_gracia,
            notas: accountForm.value.notas
        });
    };

    const prepareDataForSubmit = (isEdit = false, accountId = null) => {
        const form = accountForm.value;
        
        const accountData = {
            type: form.type,
            name: form.name.trim(),
            banco_id: form.banco_id,
            account_number: form.account_number?.trim() || null,
            last_four_digits: form.last_four_digits?.trim() || null,
            balance: Number(form.balance) || 0,
            
            // Campos específicos para tarjetas de crédito - BÁSICOS
            card_name: form.card_name?.trim() || null,
            limite_credito: Number(form.limite_credito) || 0,
            credito_disponible: Number(form.credito_disponible) || Number(form.limite_credito) || 0,
            dia_pago: Number(form.dia_pago) || 1,
            dia_corte: Number(form.dia_corte) || 1,
            tasa_interes: form.tasa_interes ? Number(form.tasa_interes) : null,
            porcentaje_pago_minimo: Number(form.porcentaje_pago_minimo) || 5,
            
            // Campos OPCIONALES de tarjeta de crédito
            porcentaje_cat: form.porcentaje_cat ? Number(form.porcentaje_cat) : null,
            anualidad: form.anualidad !== undefined && form.anualidad !== null ? Number(form.anualidad) : 0,
            gasto_exencion_anualidad: form.gasto_exencion_anualidad ? Number(form.gasto_exencion_anualidad) : null,
            porcentaje_cashback: form.porcentaje_cashback ? Number(form.porcentaje_cashback) : null,
            ratio_puntos_recompensa: form.ratio_puntos_recompensa ? Number(form.ratio_puntos_recompensa) : null,
            dias_periodo_gracia: form.dias_periodo_gracia ? Number(form.dias_periodo_gracia) : null,
            notas: form.notas?.trim() || null
        };

        // Agregar ID si es edición
        if (isEdit && accountId) {
            accountData.id = accountId;
        }

        return accountData;
    };

    return {
        // Estado
        accountForm,
        formErrors,
        isSubmitting,
        isLoadingAccountData,
        loadedAccountData,
        
        // Computed
        needsBankSelection,
        showCardFields,
        isCreditCard,
        
        // Funciones
        resetForm,
        selectAccountType,
        getNamePlaceholder,
        loadAccountForEdit,
        prepareDataForSubmit
    };
}
