export const ACCOUNT_TYPES = {
    CASH: 'cash',
    BANK: 'bank',
    DEBIT_CARD: 'debit_card',
    CREDIT_CARD: 'credit_card'
}


export const accountTypes = [
    { value: ACCOUNT_TYPES.CASH, label: 'Efectivo', icon: 'pi pi-dollar' },
    { value: ACCOUNT_TYPES.BANK, label: 'Bancaria', icon: 'pi pi-building' },
    { value: ACCOUNT_TYPES.DEBIT_CARD, label: 'Débito', icon: 'pi pi-credit-card' },
    { value: ACCOUNT_TYPES.CREDIT_CARD, label: 'Crédito', icon: 'pi pi-credit-card' }
];
