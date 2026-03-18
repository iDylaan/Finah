<script setup>
import { computed } from 'vue'
import { useAccountsStore } from '@/stores/accounts.js'

const accountsStore = useAccountsStore()

const totalBalance = computed(() => {
    return accountsStore.accounts
        .filter(acc => !acc.deleted_at)
        .reduce((sum, acc) => {
            if (acc.tipo === 'credit_card') {
                // Para crédito: lo que se debe (limit - disponible)
                const used = parseFloat(acc.limite_credito || 0) - parseFloat(acc.credito_disponible || 0)
                return sum - used
            }
            return sum + parseFloat(acc.saldo || 0)
        }, 0)
})

const accountCount = computed(() => {
    return accountsStore.accounts.filter(acc => !acc.deleted_at).length
})

const formatCurrency = (val) => {
    return new Intl.NumberFormat('es-MX', {
        style: 'currency',
        currency: 'MXN',
        minimumFractionDigits: 2
    }).format(val)
}
</script>

<template>
    <div class="rounded-2xl p-6 bg-gradient-to-br from-primary/90 to-primary text-white shadow-lg">
        <p class="text-sm opacity-80 font-medium mb-1">Balance total</p>
        <h2 class="text-3xl md:text-4xl font-bold tracking-tight">
            {{ formatCurrency(totalBalance) }}
        </h2>
        <p class="text-xs opacity-70 mt-2">
            {{ accountCount }} {{ accountCount === 1 ? 'cuenta' : 'cuentas' }} activas
        </p>
    </div>
</template>
