<script setup>
import { onMounted } from 'vue'
import { useAccountsStore } from '@/stores/accounts.js'
import BalanceTotalCard from '@/components/dashboard/BalanceTotalCard.vue'
import CuentasCarousel from '@/components/dashboard/CuentasCarousel.vue'
import ResumenMensual from '@/components/dashboard/ResumenMensual.vue'
import TransaccionesRecientes from '@/components/dashboard/TransaccionesRecientes.vue'
import PendingRecurringTransactions from '@/components/dashboard/PendingRecurringTransactions.vue'

const accountsStore = useAccountsStore()

onMounted(async () => {
    await accountsStore.fetchAccountsWithDetails()
})
</script>

<template>
    <div class="grid grid-cols-12 gap-4 md:gap-6">
        <!-- Balance total -->
        <div class="col-span-12">
            <BalanceTotalCard />
        </div>

        <!-- Cuentas carousel -->
        <div class="col-span-12">
            <CuentasCarousel />
        </div>

        <!-- Transacciones periódicas pendientes -->
        <div class="col-span-12">
            <PendingRecurringTransactions />
        </div>

        <!-- Resumen mensual + Transacciones recientes -->
        <div class="col-span-12 xl:col-span-5">
            <ResumenMensual />
        </div>
        <div class="col-span-12 xl:col-span-7">
            <TransaccionesRecientes />
        </div>
    </div>
</template>
