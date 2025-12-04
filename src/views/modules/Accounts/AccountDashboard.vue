<script setup>
import { ref, computed, onMounted, watch, nextTick } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useToast } from 'primevue/usetoast';
import { useAccountsStore } from '@/stores/accounts.js';
import { useTransactionsStore } from '@/stores/transactions.js';
import { useCategoriesStore } from '@/stores/categories.js';
import { useLevelStore } from '@/stores/levels.js';

const route = useRoute();
const router = useRouter();
const toast = useToast();

// Stores
const accountsStore = useAccountsStore();
const transactionsStore = useTransactionsStore();
const categoriesStore = useCategoriesStore();
const levelsStore = useLevelStore();

// State
const loading = ref(true);
const accountId = computed(() => route.params.id);
const activeTab = ref('0');

// Charts
const lineChart = ref(null);
const pieChart = ref(null);
const barChart = ref(null);
const balanceChartData = ref(null);
const balanceChartOptions = ref(null);
const categoryChartData = ref(null);
const categoryChartOptions = ref(null);
const monthlyChartData = ref(null);
const monthlyChartOptions = ref(null);

// Datos de la cuenta
const account = computed(() => {
    return accountsStore.accounts.find(acc => acc.id === accountId.value);
});

// Transacciones de la cuenta
const transactions = computed(() => {
    return transactionsStore.accountTransactions || [];
});

// Estadísticas calculadas
const stats = computed(() => {
    const trans = transactions.value;
    
    const ingresos = trans.filter(t => t.tipo === 'ingreso')
        .reduce((sum, t) => sum + parseFloat(t.monto), 0);
    
    const gastos = trans.filter(t => t.tipo === 'gasto')
        .reduce((sum, t) => sum + parseFloat(t.monto), 0);
    
    const transferencias = trans.filter(t => t.tipo === 'transferencia').length;
    
    return {
        totalIngresos: ingresos,
        totalGastos: gastos,
        balance: ingresos - gastos,
        totalTransacciones: trans.length,
        transferencias
    };
});

// Gastos por categoría
const gastoPorCategoria = computed(() => {
    const gastos = transactions.value.filter(t => t.tipo === 'gasto');
    const grouped = {};
    
    gastos.forEach(t => {
        const catName = t.categorias?.nombre || 'Sin categoría';
        const catColor = t.categorias?.grupos_categoria?.color || '#6366f1';
        
        if (!grouped[catName]) {
            grouped[catName] = {
                total: 0,
                color: catColor,
                count: 0
            };
        }
        grouped[catName].total += parseFloat(t.monto);
        grouped[catName].count += 1;
    });
    
    return Object.entries(grouped)
        .map(([name, data]) => ({
            nombre: name,
            total: data.total,
            color: data.color,
            count: data.count
        }))
        .sort((a, b) => b.total - a.total);
});

// Helpers
const getAccountIcon = (account) => {
    if (!account) return 'pi pi-wallet';
    if (account.banco?.nombre_icono && account.banco?.libreria_icono === 'primevue') {
        return account.banco.nombre_icono;
    }
    
    const icons = {
        'cash': 'pi pi-dollar',
        'bank': 'pi pi-building',
        'debit_card': 'pi pi-credit-card',
        'credit_card': 'pi pi-credit-card'
    };
    return icons[account.tipo] || 'pi pi-wallet';
};

const getAccountColor = (account) => {
    if (!account) return '#6366f1';
    if (account.banco?.color) return account.banco.color;
    
    const colors = {
        'cash': '#10b981',
        'bank': '#3b82f6',
        'debit_card': '#8b5cf6',
        'credit_card': '#f59e0b'
    };
    return colors[account.tipo] || '#6366f1';
};

const getAccountTypeLabel = (type) => {
    const types = {
        'cash': 'Efectivo',
        'bank': 'Cuenta Bancaria',
        'debit_card': 'Tarjeta de Débito',
        'credit_card': 'Tarjeta de Crédito'
    };
    return types[type] || type;
};

const getTransactionColor = (tipo) => {
    const colors = {
        'ingreso': 'text-green-600 dark:text-green-400',
        'gasto': 'text-red-400 dark:text-red-300',
        'transferencia': 'text-blue-600 dark:text-blue-400'
    };
    return colors[tipo] || 'text-surface-600';
};

const getTransactionBg = (tipo) => {
    const colors = {
        'ingreso': 'bg-green-50 dark:bg-green-500/10',
        'gasto': 'bg-red-50 dark:bg-red-500/10',
        'transferencia': 'bg-blue-50 dark:bg-blue-500/10'
    };
    return colors[tipo] || 'bg-surface-50';
};

const formatCurrency = (value) => {
    return new Intl.NumberFormat('es-MX', {
        style: 'currency',
        currency: 'MXN'
    }).format(value);
};

const formatDate = (date) => {
    return new Date(date).toLocaleDateString('es-MX', {
        day: '2-digit',
        month: 'short',
        year: 'numeric'
    });
};

// Cargar datos
const loadData = async () => {
    loading.value = true;
    try {
        await Promise.all([
            accountsStore.fetchAccountsWithDetails({ toast }),
            transactionsStore.fetchTransactionsByAccount(accountId.value, { toast }),
            categoriesStore.fetchCategoryGroupsWithCategories({ toast }),
            levelsStore.fetchLevels({ toast })
        ]);
        
        // Inicializar gráficas
        setupCharts();
    } catch (error) {
        console.error('Error cargando datos:', error);
        toast.add({
            severity: 'error',
            summary: 'Error',
            detail: 'Error al cargar los datos de la cuenta',
            life: 5000
        });
    } finally {
        loading.value = false;
    }
};

// Configurar gráficas
const setupCharts = () => {
    const documentStyle = getComputedStyle(document.documentElement);
    const textColor = documentStyle.getPropertyValue('--p-text-color');
    const textColorSecondary = documentStyle.getPropertyValue('--p-text-muted-color');
    const surfaceBorder = documentStyle.getPropertyValue('--p-surface-border');
    
    // Gráfica de gastos por categoría (Pie)
    if (gastoPorCategoria.value.length > 0) {
        categoryChartData.value = {
            labels: gastoPorCategoria.value.map(c => c.nombre),
            datasets: [{
                data: gastoPorCategoria.value.map(c => c.total),
                backgroundColor: gastoPorCategoria.value.map(c => c.color),
                hoverBackgroundColor: gastoPorCategoria.value.map(c => c.color + 'dd'),
                borderWidth: 0
            }]
        };
        
        categoryChartOptions.value = {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: {
                        usePointStyle: true,
                        color: textColor,
                        padding: 15,
                        font: {
                            size: 12
                        }
                    }
                },
                tooltip: {
                    callbacks: {
                        label: (context) => {
                            const label = context.label || '';
                            const value = formatCurrency(context.parsed);
                            const total = context.dataset.data.reduce((a, b) => a + b, 0);
                            const percentage = ((context.parsed / total) * 100).toFixed(1);
                            return `${label}: ${value} (${percentage}%)`;
                        }
                    }
                }
            }
        };
    }
    
    // Gráfica de ingresos vs gastos mensual (Bar)
    const monthlyData = getMonthlyData();
    monthlyChartData.value = {
        labels: monthlyData.labels,
        datasets: [
            {
                label: 'Ingresos',
                backgroundColor: '#10b981',
                borderColor: '#10b981',
                data: monthlyData.ingresos
            },
            {
                label: 'Gastos',
                backgroundColor: '#ef4444',
                borderColor: '#ef4444',
                data: monthlyData.gastos
            }
        ]
    };
    
    monthlyChartOptions.value = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                labels: {
                    color: textColor
                }
            },
            tooltip: {
                callbacks: {
                    label: (context) => {
                        return `${context.dataset.label}: ${formatCurrency(context.parsed.y)}`;
                    }
                }
            }
        },
        scales: {
            x: {
                ticks: {
                    color: textColorSecondary,
                    font: {
                        weight: 500
                    }
                },
                grid: {
                    display: false,
                    drawBorder: false
                }
            },
            y: {
                ticks: {
                    color: textColorSecondary,
                    callback: (value) => formatCurrency(value)
                },
                grid: {
                    color: surfaceBorder,
                    drawBorder: false
                }
            }
        }
    };
    
    // Gráfica de evolución del saldo (Line)
    const balanceData = getBalanceEvolution();
    balanceChartData.value = {
        labels: balanceData.labels,
        datasets: [{
            label: 'Saldo',
            data: balanceData.values,
            fill: true,
            backgroundColor: getAccountColor(account.value) + '20',
            borderColor: getAccountColor(account.value),
            tension: 0.4,
            pointBackgroundColor: getAccountColor(account.value),
            pointBorderColor: getAccountColor(account.value),
            pointRadius: 4,
            pointHoverRadius: 6
        }]
    };
    
    balanceChartOptions.value = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                display: false
            },
            tooltip: {
                callbacks: {
                    label: (context) => {
                        return `Saldo: ${formatCurrency(context.parsed.y)}`;
                    }
                }
            }
        },
        scales: {
            x: {
                ticks: {
                    color: textColorSecondary
                },
                grid: {
                    color: surfaceBorder,
                    drawBorder: false
                }
            },
            y: {
                ticks: {
                    color: textColorSecondary,
                    callback: (value) => formatCurrency(value)
                },
                grid: {
                    color: surfaceBorder,
                    drawBorder: false
                }
            }
        }
    };
    
    nextTick(() => {
        refreshCharts();
    });
};

// Obtener datos mensuales
const getMonthlyData = () => {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    const currentMonth = new Date().getMonth();
    const last6Months = [];
    
    for (let i = 5; i >= 0; i--) {
        const monthIndex = (currentMonth - i + 12) % 12;
        last6Months.push(months[monthIndex]);
    }
    
    const ingresos = new Array(6).fill(0);
    const gastos = new Array(6).fill(0);
    
    transactions.value.forEach(t => {
        const transDate = new Date(t.fecha_ocurrencia);
        const monthDiff = (new Date().getFullYear() - transDate.getFullYear()) * 12 
            + (new Date().getMonth() - transDate.getMonth());
        
        if (monthDiff >= 0 && monthDiff < 6) {
            const index = 5 - monthDiff;
            if (t.tipo === 'ingreso') {
                ingresos[index] += parseFloat(t.monto);
            } else if (t.tipo === 'gasto') {
                gastos[index] += parseFloat(t.monto);
            }
        }
    });
    
    return { labels: last6Months, ingresos, gastos };
};

// Obtener evolución del saldo
const getBalanceEvolution = () => {
    const sortedTransactions = [...transactions.value].sort((a, b) => 
        new Date(a.fecha_ocurrencia) - new Date(b.fecha_ocurrencia)
    );
    
    const labels = [];
    const values = [];
    let currentBalance = 0;
    
    sortedTransactions.forEach((t, index) => {
        if (t.tipo === 'ingreso') {
            currentBalance += parseFloat(t.monto);
        } else if (t.tipo === 'gasto') {
            currentBalance -= parseFloat(t.monto);
        }
        
        // Mostrar cada 5 transacciones o la última
        if (index % 5 === 0 || index === sortedTransactions.length - 1) {
            labels.push(formatDate(t.fecha_ocurrencia));
            values.push(currentBalance);
        }
    });
    
    return { labels, values };
};

// Refrescar gráficas
const refreshCharts = () => {
    const charts = [lineChart, pieChart, barChart];
    charts.forEach(chartRef => {
        if (chartRef.value && chartRef.value.chart) {
            chartRef.value.chart.update();
        }
    });
};

// Volver a cuentas
const goBack = () => {
    router.push('/accounts');
};

onMounted(() => {
    loadData();
});

watch(() => route.params.id, () => {
    if (route.params.id) {
        loadData();
    }
});
</script>

<template>
    <PageLayout>
        <template #header>
            <div class="flex items-center gap-3">
                <Button 
                    icon="pi pi-arrow-left" 
                    severity="secondary" 
                    text 
                    rounded
                    @click="goBack"
                />
                <div class="flex items-center gap-3">
                    <div v-if="account" 
                        class="w-12 h-12 rounded-xl flex items-center justify-center text-white text-xl"
                        :style="{ backgroundColor: getAccountColor(account) }">
                        <i v-if="account.banco?.libreria_icono === 'primevue'"
                            :class="getAccountIcon(account)"></i>
                        <span v-else-if="account.banco?.libreria_icono === 'material'"
                            class="material-symbols-rounded text-2xl">
                            {{ account.banco?.nombre_icono }}
                        </span>
                        <i v-else :class="getAccountIcon(account)"></i>
                    </div>
                    <div>
                        <h1 class="text-2xl font-bold text-surface-900 dark:text-surface-0">
                            {{ account?.nombre || 'Cargando...' }}
                        </h1>
                        <p class="text-sm text-surface-600 dark:text-surface-400">
                            {{ account ? getAccountTypeLabel(account.tipo) : '' }}
                        </p>
                    </div>
                </div>
            </div>
        </template>

        <!-- Loading State -->
        <div v-if="loading" class="flex items-center justify-center py-16">
            <ProgressSpinner />
        </div>

        <!-- Dashboard Content -->
        <div v-else-if="account" class="space-y-6">
            <!-- Stats Cards -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                <!-- Saldo/Crédito Actual -->
                <div class="card">
                    <div class="flex items-start justify-between mb-3">
                        <div>
                            <p class="text-sm text-surface-600 dark:text-surface-400 mb-1">
                                {{ account.tipo === 'credit_card' ? 'Crédito Disponible' : 'Saldo Actual' }}
                            </p>
                            <p class="text-2xl font-bold text-surface-900 dark:text-surface-0">
                                {{ formatCurrency(account.tipo === 'credit_card' ? account.credito_disponible : account.saldo) }}
                            </p>
                        </div>
                        <div class="w-10 h-10 rounded-lg flex items-center justify-center"
                            :style="{ backgroundColor: getAccountColor(account) + '20', color: getAccountColor(account) }">
                            <i class="pi pi-wallet text-xl"></i>
                        </div>
                    </div>
                    <p v-if="account.tipo === 'credit_card'" class="text-xs text-surface-500">
                        Límite: {{ formatCurrency(account.limite_credito) }}
                    </p>
                </div>

                <!-- Total Ingresos -->
                <div class="card">
                    <div class="flex items-start justify-between mb-3">
                        <div>
                            <p class="text-sm text-surface-600 dark:text-surface-400 mb-1">Total Ingresos</p>
                            <p class="text-2xl font-bold text-green-600 dark:text-green-400">
                                {{ formatCurrency(stats.totalIngresos) }}
                            </p>
                        </div>
                        <div class="w-10 h-10 rounded-lg bg-green-100 dark:bg-green-500/20 flex items-center justify-center text-green-600 dark:text-green-400">
                            <i class="pi pi-arrow-up text-xl"></i>
                        </div>
                    </div>
                </div>

                <!-- Total Gastos -->
                <div class="card">
                    <div class="flex items-start justify-between mb-3">
                        <div>
                            <p class="text-sm text-surface-600 dark:text-surface-400 mb-1">Total Gastos</p>
                            <p class="text-2xl font-bold text-red-500 dark:text-red-400">
                                {{ formatCurrency(stats.totalGastos) }}
                            </p>
                        </div>
                        <div class="w-10 h-10 rounded-lg bg-red-100 dark:bg-red-500/20 flex items-center justify-center text-red-500 dark:text-red-400">
                            <i class="pi pi-arrow-down text-xl"></i>
                        </div>
                    </div>
                </div>

                <!-- Total Transacciones -->
                <div class="card">
                    <div class="flex items-start justify-between mb-3">
                        <div>
                            <p class="text-sm text-surface-600 dark:text-surface-400 mb-1">Transacciones</p>
                            <p class="text-2xl font-bold text-surface-900 dark:text-surface-0">
                                {{ stats.totalTransacciones }}
                            </p>
                        </div>
                        <div class="w-10 h-10 rounded-lg bg-blue-100 dark:bg-blue-500/20 flex items-center justify-center text-blue-600 dark:text-blue-400">
                            <i class="pi pi-list text-xl"></i>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Tabs -->
            <Tabs :value="activeTab">
                <TabList>
                    <Tab value="0">Resumen</Tab>
                    <Tab value="1">Transacciones</Tab>
                    <Tab value="2">Estadísticas</Tab>
                </TabList>

                <TabPanels>
                    <!-- Resumen Tab -->
                    <TabPanel value="0">
                        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                            <!-- Evolución del Saldo -->
                            <div class="card">
                                <h3 class="text-lg font-semibold mb-4 text-surface-900 dark:text-surface-0">
                                    Evolución del Saldo
                                </h3>
                                <div class="h-64">
                                    <Chart 
                                        v-if="balanceChartData"
                                        ref="lineChart" 
                                        type="line" 
                                        :data="balanceChartData" 
                                        :options="balanceChartOptions"
                                    />
                                    <div v-else class="flex items-center justify-center h-full text-surface-500">
                                        No hay datos suficientes
                                    </div>
                                </div>
                            </div>

                            <!-- Últimas Transacciones -->
                            <div class="card">
                                <div class="flex items-center justify-between mb-4">
                                    <h3 class="text-lg font-semibold text-surface-900 dark:text-surface-0">
                                        Últimas Transacciones
                                    </h3>
                                    <Button 
                                        label="Ver todas" 
                                        text 
                                        size="small"
                                        @click="activeTab = '1'"
                                    />
                                </div>
                                <div class="space-y-3">
                                    <div 
                                        v-for="transaction in transactions.slice(0, 5)" 
                                        :key="transaction.id"
                                        class="flex items-center justify-between p-3 rounded-lg"
                                        :class="getTransactionBg(transaction.tipo)"
                                    >
                                        <div class="flex items-center gap-3">
                                            <div class="w-10 h-10 rounded-lg flex items-center justify-center"
                                                :style="{ 
                                                    backgroundColor: transaction.categorias?.grupos_categoria?.color + '20',
                                                    color: transaction.categorias?.grupos_categoria?.color 
                                                }">
                                                <i v-if="transaction.categorias?.biblioteca_iconos === 'primevue'"
                                                    :class="transaction.categorias?.nombre_icono" class="text-sm"></i>
                                                <span v-else-if="transaction.categorias?.biblioteca_iconos === 'material'"
                                                    class="material-symbols-rounded text-base">
                                                    {{ transaction.categorias?.nombre_icono }}
                                                </span>
                                            </div>
                                            <div>
                                                <p class="font-medium text-sm text-surface-900 dark:text-surface-0">
                                                    {{ transaction.categorias?.nombre || 'Sin categoría' }}
                                                </p>
                                                <p class="text-xs text-surface-500">
                                                    {{ formatDate(transaction.fecha_ocurrencia) }}
                                                </p>
                                            </div>
                                        </div>
                                        <p class="font-semibold" :class="getTransactionColor(transaction.tipo)">
                                            {{ transaction.tipo === 'gasto' ? '-' : '+' }}{{ formatCurrency(transaction.monto) }}
                                        </p>
                                    </div>
                                    <div v-if="transactions.length === 0" class="text-center py-8 text-surface-500">
                                        No hay transacciones registradas
                                    </div>
                                </div>
                            </div>
                        </div>
                    </TabPanel>

                    <!-- Transacciones Tab -->
                    <TabPanel value="1">
                        <div class="card">
                            <DataTable 
                                :value="transactions" 
                                :paginator="true" 
                                :rows="10"
                                :rowsPerPageOptions="[5, 10, 20, 50]"
                                filterDisplay="row"
                                :globalFilterFields="['categorias.nombre', 'descripcion']"
                                stripedRows
                                responsiveLayout="scroll"
                            >
                                <template #empty>
                                    <div class="text-center py-8 text-surface-500">
                                        No hay transacciones registradas
                                    </div>
                                </template>

                                <Column field="fecha_ocurrencia" header="Fecha" sortable style="min-width: 120px">
                                    <template #body="{ data }">
                                        {{ formatDate(data.fecha_ocurrencia) }}
                                    </template>
                                </Column>

                                <Column field="categorias.nombre" header="Categoría" sortable style="min-width: 200px">
                                    <template #body="{ data }">
                                        <div class="flex items-center gap-2">
                                            <div class="w-8 h-8 rounded flex items-center justify-center"
                                                :style="{ 
                                                    backgroundColor: data.categorias?.grupos_categoria?.color + '20',
                                                    color: data.categorias?.grupos_categoria?.color 
                                                }">
                                                <i v-if="data.categorias?.biblioteca_iconos === 'primevue'"
                                                    :class="data.categorias?.nombre_icono" class="text-sm"></i>
                                                <span v-else-if="data.categorias?.biblioteca_iconos === 'material'"
                                                    class="material-symbols-rounded text-sm">
                                                    {{ data.categorias?.nombre_icono }}
                                                </span>
                                            </div>
                                            <span>{{ data.categorias?.nombre || 'Sin categoría' }}</span>
                                        </div>
                                    </template>
                                </Column>

                                <Column field="tipo" header="Tipo" sortable style="min-width: 120px">
                                    <template #body="{ data }">
                                        <Tag 
                                            :value="data.tipo"
                                            :severity="data.tipo === 'ingreso' ? 'success' : data.tipo === 'gasto' ? 'danger' : 'info'"
                                        />
                                    </template>
                                </Column>

                                <Column field="monto" header="Monto" sortable style="min-width: 150px">
                                    <template #body="{ data }">
                                        <span class="font-semibold" :class="getTransactionColor(data.tipo)">
                                            {{ data.tipo === 'gasto' ? '-' : '+' }}{{ formatCurrency(data.monto) }}
                                        </span>
                                    </template>
                                </Column>

                                <Column field="niveles.nombre" header="Nivel" sortable style="min-width: 150px">
                                    <template #body="{ data }">
                                        <div v-if="data.niveles" class="flex items-center gap-2">
                                            <div class="w-3 h-3 rounded-full" 
                                                :style="{ backgroundColor: data.niveles.color }"></div>
                                            <span>{{ data.niveles.nombre }}</span>
                                        </div>
                                        <span v-else class="text-surface-400">-</span>
                                    </template>
                                </Column>

                                <Column field="descripcion" header="Descripción" style="min-width: 250px">
                                    <template #body="{ data }">
                                        <span class="text-surface-600 dark:text-surface-400">
                                            {{ data.descripcion || '-' }}
                                        </span>
                                    </template>
                                </Column>
                            </DataTable>
                        </div>
                    </TabPanel>

                    <!-- Estadísticas Tab -->
                    <TabPanel value="2">
                        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                            <!-- Gastos por Categoría -->
                            <div class="card">
                                <h3 class="text-lg font-semibold mb-4 text-surface-900 dark:text-surface-0">
                                    Gastos por Categoría
                                </h3>
                                <div class="h-80">
                                    <Chart 
                                        v-if="categoryChartData"
                                        ref="pieChart" 
                                        type="doughnut" 
                                        :data="categoryChartData" 
                                        :options="categoryChartOptions"
                                    />
                                    <div v-else class="flex items-center justify-center h-full text-surface-500">
                                        No hay gastos registrados
                                    </div>
                                </div>
                            </div>

                            <!-- Ingresos vs Gastos Mensual -->
                            <div class="card">
                                <h3 class="text-lg font-semibold mb-4 text-surface-900 dark:text-surface-0">
                                    Ingresos vs Gastos (Últimos 6 meses)
                                </h3>
                                <div class="h-80">
                                    <Chart 
                                        v-if="monthlyChartData"
                                        ref="barChart" 
                                        type="bar" 
                                        :data="monthlyChartData" 
                                        :options="monthlyChartOptions"
                                    />
                                </div>
                            </div>

                            <!-- Tabla de Categorías -->
                            <div class="card lg:col-span-2">
                                <h3 class="text-lg font-semibold mb-4 text-surface-900 dark:text-surface-0">
                                    Resumen por Categoría
                                </h3>
                                <DataTable :value="gastoPorCategoria" :rows="5" :paginator="true">
                                    <Column field="nombre" header="Categoría">
                                        <template #body="{ data }">
                                            <div class="flex items-center gap-2">
                                                <div class="w-4 h-4 rounded" :style="{ backgroundColor: data.color }"></div>
                                                <span>{{ data.nombre }}</span>
                                            </div>
                                        </template>
                                    </Column>
                                    <Column field="count" header="Transacciones" sortable></Column>
                                    <Column field="total" header="Total" sortable>
                                        <template #body="{ data }">
                                            <span class="font-semibold text-red-500">
                                                {{ formatCurrency(data.total) }}
                                            </span>
                                        </template>
                                    </Column>
                                </DataTable>
                            </div>
                        </div>
                    </TabPanel>
                </TabPanels>
            </Tabs>
        </div>

        <!-- Account Not Found -->
        <div v-else class="card text-center py-16">
            <i class="pi pi-exclamation-circle text-6xl text-surface-400 mb-4"></i>
            <h2 class="text-2xl font-bold text-surface-900 dark:text-surface-0 mb-2">
                Cuenta no encontrada
            </h2>
            <p class="text-surface-600 dark:text-surface-400 mb-6">
                La cuenta que buscas no existe o no tienes acceso a ella
            </p>
            <Button label="Volver a Cuentas" @click="goBack" />
        </div>
    </PageLayout>
</template>
