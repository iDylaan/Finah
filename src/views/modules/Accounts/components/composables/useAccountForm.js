import { ref, computed } from 'vue';
import { ACCOUNT_TYPES } from '@/assets/constants/account-types';

export function useAccountForm() {
    // Estado del formulario
    const accountForm = ref({
        type: 'cash',
        bank_id: null,
        name: '',
        account_number: '',
        last_four_digits: '',
        balance: 0,
        card_name: '',
        credit_limit: 0,
        available_credit: 0,
        payment_day: 1,
        cutoff_day: 1,
        interest_rate: null,
        min_payment_percent: 5,
        cat_percentage: null,
        annual_fee: 0,
        annual_fee_waiver_spending: null,
        cashback_percentage: null,
        rewards_points_ratio: null,
        grace_period_days: null,
        notes: ''
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
            bank_id: null,
            name: '',
            account_number: '',
            last_four_digits: '',
            balance: 0,
            card_name: '',
            credit_limit: 0,
            available_credit: 0,
            payment_day: 1,
            cutoff_day: 1,
            interest_rate: null,
            min_payment_percent: 5,
            cat_percentage: null,
            annual_fee: 0,
            annual_fee_waiver_spending: null,
            cashback_percentage: null,
            rewards_points_ratio: null,
            grace_period_days: null,
            notes: ''
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
                credit_limit: 0,
                available_credit: 0,
                payment_day: 1,
                cutoff_day: 1,
                interest_rate: null,
                cat_percentage: null,
                annual_fee: 0,
                annual_fee_waiver_spending: null,
                cashback_percentage: null,
                rewards_points_ratio: null,
                grace_period_days: null,
                notes: ''
            });
        }

        // Limpiar últimos 4 dígitos si no es tarjeta
        if (!['debit_card', 'credit_card'].includes(type)) {
            accountForm.value.last_four_digits = '';
        }

        // Limpiar selección de banco si no es necesario
        if (!['bank', 'debit_card', 'credit_card'].includes(type)) {
            accountForm.value.bank_id = null;
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
            bank_id: account.metadata?.bank_id || account.credit_card?.bank_id || null,
            name: account.name || '',
            account_number: account.metadata?.account_number || '',
            last_four_digits: account.metadata?.last4 || account.credit_card?.last_four_digits || '',
            balance: account.balance || 0,
            
            // Campos BÁSICOS de tarjeta de crédito
            card_name: account.credit_card?.card_name || '',
            credit_limit: account.credit_card?.credit_limit || 0,
            available_credit: account.credit_card?.available_credit || 0,
            payment_day: account.credit_card?.payment_day || 1,
            cutoff_day: account.credit_card?.cutoff_day || 1,
            interest_rate: account.credit_card?.interest_rate || null,
            min_payment_percent: account.credit_card?.min_payment_percent || 5,
            
            // Campos OPCIONALES de tarjeta de crédito
            cat_percentage: account.credit_card?.cat_percentage || null,
            annual_fee: account.credit_card?.annual_fee || 0,
            annual_fee_waiver_spending: account.credit_card?.annual_fee_waiver_spending || null,
            cashback_percentage: account.credit_card?.cashback_percentage || null,
            rewards_points_ratio: account.credit_card?.rewards_points_ratio || null,
            grace_period_days: account.credit_card?.grace_period_days || null,
            notes: account.credit_card?.notes || ''
        };

        console.log('📝 Formulario cargado con datos:', accountForm.value);
        console.log('📝 Campos de tarjeta específicos:', {
            cat_percentage: accountForm.value.cat_percentage,
            annual_fee: accountForm.value.annual_fee,
            annual_fee_waiver_spending: accountForm.value.annual_fee_waiver_spending,
            cashback_percentage: accountForm.value.cashback_percentage,
            rewards_points_ratio: accountForm.value.rewards_points_ratio,
            grace_period_days: accountForm.value.grace_period_days,
            notes: accountForm.value.notes
        });
    };

    const prepareDataForSubmit = (isEdit = false, accountId = null) => {
        const form = accountForm.value;
        
        const accountData = {
            type: form.type,
            name: form.name.trim(),
            bank_id: form.bank_id,
            account_number: form.account_number?.trim() || null,
            last_four_digits: form.last_four_digits?.trim() || null,
            balance: Number(form.balance) || 0,
            
            // Campos específicos para tarjetas de crédito - BÁSICOS
            card_name: form.card_name?.trim() || null,
            credit_limit: Number(form.credit_limit) || 0,
            available_credit: Number(form.available_credit) || Number(form.credit_limit) || 0,
            payment_day: Number(form.payment_day) || 1,
            cutoff_day: Number(form.cutoff_day) || 1,
            interest_rate: form.interest_rate ? Number(form.interest_rate) : null,
            min_payment_percent: Number(form.min_payment_percent) || 5,
            
            // Campos OPCIONALES de tarjeta de crédito
            cat_percentage: form.cat_percentage ? Number(form.cat_percentage) : null,
            annual_fee: form.annual_fee !== undefined && form.annual_fee !== null ? Number(form.annual_fee) : 0,
            annual_fee_waiver_spending: form.annual_fee_waiver_spending ? Number(form.annual_fee_waiver_spending) : null,
            cashback_percentage: form.cashback_percentage ? Number(form.cashback_percentage) : null,
            rewards_points_ratio: form.rewards_points_ratio ? Number(form.rewards_points_ratio) : null,
            grace_period_days: form.grace_period_days ? Number(form.grace_period_days) : null,
            notes: form.notes?.trim() || null
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
