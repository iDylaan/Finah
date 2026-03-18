<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAccountsStore } from '@/stores/accounts.js'
import { accountTypes } from '@/assets/constants/account-types.js'

const router = useRouter()
const accountsStore = useAccountsStore()

const activeAccounts = computed(() => {
    return accountsStore.accounts.filter(acc => !acc.deleted_at)
})

const getTypeLabel = (tipo) => {
    return accountTypes.find(t => t.value === tipo)?.label || tipo
}

const getTypeIcon = (tipo) => {
    const icons = {
        cash: 'payments',
        bank: 'account_balance',
        debit_card: 'credit_card',
        credit_card: 'credit_score'
    }
    return icons[tipo] || 'account_balance_wallet'
}

const getAccountBalance = (acc) => {
    if (acc.tipo === 'credit_card') {
        return parseFloat(acc.credito_disponible || 0)
    }
    return parseFloat(acc.saldo || 0)
}

const getBalanceLabel = (acc) => {
    return acc.tipo === 'credit_card' ? 'Disponible' : 'Saldo'
}

const formatCurrency = (val) => {
    return new Intl.NumberFormat('es-MX', {
        style: 'currency',
        currency: 'MXN',
        minimumFractionDigits: 2
    }).format(val)
}

const goToAccount = (acc) => {
    router.push(`/accounts/${acc.id}/dashboard`)
}
</script>

<template>
    <div>
        <div class="flex items-center justify-between mb-3">
            <h3 class="text-lg font-semibold text-surface-900 dark:text-surface-0">Mis Cuentas</h3>
            <router-link
                to="/accounts"
                class="text-sm text-primary font-medium hover:underline no-underline"
            >
                Ver todas
            </router-link>
        </div>

        <div v-if="activeAccounts.length === 0" class="text-center py-8 text-surface-400">
            <span class="material-symbols-outlined text-4xl mb-2 block">account_balance_wallet</span>
            <p class="text-sm">Aún no tienes cuentas</p>
        </div>

        <div v-else class="flex gap-3 overflow-x-auto pb-2 snap-x snap-mandatory -mx-1 px-1 scrollbar-hide">
            <div
                v-for="acc in activeAccounts"
                :key="acc.id"
                class="snap-start shrink-0 w-52 rounded-2xl p-4 cursor-pointer transition-all hover:shadow-md border border-surface-200 dark:border-surface-700 bg-surface-0 dark:bg-surface-800"
                @click="goToAccount(acc)"
            >
                <div class="flex items-center gap-2 mb-3">
                    <div
                        class="w-8 h-8 rounded-lg flex items-center justify-center"
                        :style="{ backgroundColor: acc.banco?.color || acc.metadatos?.color || 'var(--p-primary-color)', opacity: 0.9 }"
                    >
                        <span class="material-symbols-outlined text-white text-base">{{ getTypeIcon(acc.tipo) }}</span>
                    </div>
                    <div class="min-w-0 flex-1">
                        <p class="text-sm font-semibold text-surface-900 dark:text-surface-0 truncate">{{ acc.nombre }}</p>
                        <p class="text-xs text-surface-400">{{ getTypeLabel(acc.tipo) }}</p>
                    </div>
                </div>
                <p class="text-xs text-surface-500 dark:text-surface-400">{{ getBalanceLabel(acc) }}</p>
                <p class="text-lg font-bold text-surface-900 dark:text-surface-0">
                    {{ formatCurrency(getAccountBalance(acc)) }}
                </p>
            </div>
        </div>
    </div>
</template>

<style scoped>
.scrollbar-hide {
    -ms-overflow-style: none;
    scrollbar-width: none;
}
.scrollbar-hide::-webkit-scrollbar {
    display: none;
}
</style>
