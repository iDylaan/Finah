// Test Script para verificar el flujo de datos de cuentas
console.log('=== TEST: Verificando flujo de datos de cuentas ===');

// Simular datos de formulario de tarjeta de crédito
const mockFormData = {
    type: 'credit_card',
    name: 'Tarjeta Test',
    bank_id: 'bank-123',
    card_name: 'BBVA Oro Test',
    last_four_digits: '1234',
    credit_limit: 50000,
    available_credit: 45000,
    payment_day: 15,
    cutoff_day: 10,
    interest_rate: 35.5,
    min_payment_percent: 5,
    cat_percentage: 45.2,
    annual_fee: 800,
    annual_fee_waiver_spending: 60000,
    cashback_percentage: 1.5,
    rewards_points_ratio: 0.5,
    grace_period_days: 25,
    notes: 'Tarjeta de prueba con todos los beneficios'
};

// Simular la función prepareDataForSubmit
function prepareDataForSubmit(formData, isEdit = false, accountId = null) {
    const accountData = {
        type: formData.type,
        name: formData.name.trim(),
        bank_id: formData.bank_id,
        account_number: formData.account_number?.trim() || null,
        last_four_digits: formData.last_four_digits?.trim() || null,
        balance: Number(formData.balance) || 0,
        
        // Campos específicos para tarjetas de crédito - BÁSICOS
        card_name: formData.card_name?.trim() || null,
        credit_limit: Number(formData.credit_limit) || 0,
        available_credit: Number(formData.available_credit) || Number(formData.credit_limit) || 0,
        payment_day: Number(formData.payment_day) || 1,
        cutoff_day: Number(formData.cutoff_day) || 1,
        interest_rate: formData.interest_rate ? Number(formData.interest_rate) : null,
        min_payment_percent: Number(formData.min_payment_percent) || 5,
        
        // Campos OPCIONALES de tarjeta de crédito
        cat_percentage: formData.cat_percentage ? Number(formData.cat_percentage) : null,
        annual_fee: formData.annual_fee !== undefined && formData.annual_fee !== null ? Number(formData.annual_fee) : 0,
        annual_fee_waiver_spending: formData.annual_fee_waiver_spending ? Number(formData.annual_fee_waiver_spending) : null,
        cashback_percentage: formData.cashback_percentage ? Number(formData.cashback_percentage) : null,
        rewards_points_ratio: formData.rewards_points_ratio ? Number(formData.rewards_points_ratio) : null,
        grace_period_days: formData.grace_period_days ? Number(formData.grace_period_days) : null,
        notes: formData.notes?.trim() || null
    };

    // Agregar ID si es edición
    if (isEdit && accountId) {
        accountData.id = accountId;
    }

    return accountData;
}

// Simular datos de la base de datos que llegarían en modo edición
const mockDatabaseAccount = {
    id: 'acc-123',
    name: 'Tarjeta BBVA Oro',
    type: 'credit_card',
    balance: 0,
    credit_card: {
        bank_id: 'bank-123',
        card_name: 'BBVA Oro',
        last_four_digits: '5678',
        credit_limit: 60000,
        available_credit: 55000,
        payment_day: 20,
        cutoff_day: 15,
        interest_rate: 38.5,
        min_payment_percent: 4,
        cat_percentage: 47.8,
        annual_fee: 1200,
        annual_fee_waiver_spending: 80000,
        cashback_percentage: 2.0,
        rewards_points_ratio: 0.8,
        grace_period_days: 30,
        notes: 'Tarjeta con beneficios premium'
    }
};

// Test de preparación de datos para creación
console.log('\n--- TEST 1: Preparación de datos para CREACIÓN ---');
const preparedForCreate = prepareDataForSubmit(mockFormData, false);
console.log('Datos preparados para crear:', preparedForCreate);

// Test de preparación de datos para edición
console.log('\n--- TEST 2: Preparación de datos para EDICIÓN ---');
const preparedForEdit = prepareDataForSubmit(mockFormData, true, 'acc-123');
console.log('Datos preparados para editar:', preparedForEdit);

// Test de carga de datos desde base de datos
console.log('\n--- TEST 3: Carga de datos desde BD ---');
const loadedForm = {
    type: mockDatabaseAccount.type || 'cash',
    bank_id: mockDatabaseAccount.metadata?.bank_id || mockDatabaseAccount.credit_card?.bank_id || null,
    name: mockDatabaseAccount.name || '',
    account_number: mockDatabaseAccount.metadata?.account_number || '',
    last_four_digits: mockDatabaseAccount.metadata?.last4 || mockDatabaseAccount.credit_card?.last_four_digits || '',
    balance: mockDatabaseAccount.balance || 0,
    
    // Campos BÁSICOS de tarjeta de crédito
    card_name: mockDatabaseAccount.credit_card?.card_name || '',
    credit_limit: mockDatabaseAccount.credit_card?.credit_limit || 0,
    available_credit: mockDatabaseAccount.credit_card?.available_credit || 0,
    payment_day: mockDatabaseAccount.credit_card?.payment_day || 1,
    cutoff_day: mockDatabaseAccount.credit_card?.cutoff_day || 1,
    interest_rate: mockDatabaseAccount.credit_card?.interest_rate || null,
    min_payment_percent: mockDatabaseAccount.credit_card?.min_payment_percent || 5,
    
    // Campos OPCIONALES de tarjeta de crédito
    cat_percentage: mockDatabaseAccount.credit_card?.cat_percentage || null,
    annual_fee: mockDatabaseAccount.credit_card?.annual_fee || 0,
    annual_fee_waiver_spending: mockDatabaseAccount.credit_card?.annual_fee_waiver_spending || null,
    cashback_percentage: mockDatabaseAccount.credit_card?.cashback_percentage || null,
    rewards_points_ratio: mockDatabaseAccount.credit_card?.rewards_points_ratio || null,
    grace_period_days: mockDatabaseAccount.credit_card?.grace_period_days || null,
    notes: mockDatabaseAccount.credit_card?.notes || ''
};

console.log('Formulario cargado desde BD:', loadedForm);

// Verificar que los datos opcionales se conserven
console.log('\n--- VERIFICACIÓN DE CAMPOS OPCIONALES ---');
console.log('CAT %:', loadedForm.cat_percentage);
console.log('Anualidad:', loadedForm.annual_fee);
console.log('Gasto exención:', loadedForm.annual_fee_waiver_spending);
console.log('Cashback %:', loadedForm.cashback_percentage);
console.log('Puntos ratio:', loadedForm.rewards_points_ratio);
console.log('Días gracia:', loadedForm.grace_period_days);
console.log('Notas:', loadedForm.notes);

console.log('\n=== FIN DEL TEST ===');

export default {
    prepareDataForSubmit,
    mockFormData,
    mockDatabaseAccount
};
