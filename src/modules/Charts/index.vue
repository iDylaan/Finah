<script setup>
import { onMounted, ref, watch, nextTick } from 'vue';

// STORES
import { useUIStore } from '@/stores/ui';
const UI = useUIStore();

const lineData = ref(null);
const pieData = ref(null);
const polarData = ref(null);
const barData = ref(null);
const radarData = ref(null);
const lineOptions = ref(null);
const pieOptions = ref(null);
const polarOptions = ref(null);
const barOptions = ref(null);
const radarOptions = ref(null);

// Referencias a los componentes Chart para poder actualizar manualmente
const lineChart = ref(null);
const barChart = ref(null);
const pieChart = ref(null);
const doughnutChart = ref(null);
const polarChart = ref(null);
const radarChart = ref(null);

onMounted(() => {
    setColorOptions();
});

function setColorOptions() {
    const documentStyle = getComputedStyle(document.documentElement);
    const textColor = documentStyle.getPropertyValue('--p-text-color');
    const textColorSecondary = documentStyle.getPropertyValue('--p-text-muted-color');
    const surfaceBorder = documentStyle.getPropertyValue('--p-surface-border');
    
    // Colores primarios dinámicos
    const primary500 = documentStyle.getPropertyValue('--p-primary-500');
    const primary400 = documentStyle.getPropertyValue('--p-primary-400');
    const primary300 = documentStyle.getPropertyValue('--p-primary-300');
    const primary200 = documentStyle.getPropertyValue('--p-primary-200');
    const primary100 = documentStyle.getPropertyValue('--p-primary-100');


    // Bar Chart
    barData.value = {
        labels: ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio'],
        datasets: [
            {
                label: 'Ingresos',
                backgroundColor: primary500,
                borderColor: primary500,
                data: [65, 59, 80, 81, 56, 55, 40]
            },
            {
                label: 'Gastos',
                backgroundColor: primary200,
                borderColor: primary200,
                data: [28, 48, 40, 19, 86, 27, 90]
            }
        ]
    };
    
    barOptions.value = {
        responsive: true,
        plugins: {
            legend: {
                labels: {
                    color: textColor
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
                    color: textColorSecondary
                },
                grid: {
                    color: surfaceBorder,
                    drawBorder: false
                }
            }
        }
    };

    // Pie Chart
    pieData.value = {
        labels: ['Inversiones', 'Ahorros', 'Gastos'],
        datasets: [
            {
                data: [540, 325, 702],
                backgroundColor: [primary500, primary300, primary100],
                hoverBackgroundColor: [primary400, primary200, primary100],
                borderWidth: 0
            }
        ]
    };

    pieOptions.value = {
        responsive: true,
        plugins: {
            legend: {
                labels: {
                    usePointStyle: true,
                    color: textColor
                }
            }
        }
    };

    // Line Chart
    lineData.value = {
        labels: ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio'],
        datasets: [
            {
                label: 'Tendencia Principal',
                data: [65, 59, 80, 81, 56, 55, 40],
                fill: false,
                backgroundColor: primary500,
                borderColor: primary500,
                tension: 0.4,
                pointBackgroundColor: primary500,
                pointBorderColor: primary500,
                pointHoverBackgroundColor: primary400,
                pointHoverBorderColor: primary400
            },
            {
                label: 'Tendencia Secundaria',
                data: [28, 48, 40, 19, 86, 27, 90],
                fill: false,
                backgroundColor: primary200,
                borderColor: primary200,
                tension: 0.4,
                pointBackgroundColor: primary200,
                pointBorderColor: primary200,
                pointHoverBackgroundColor: primary100,
                pointHoverBorderColor: primary100
            }
        ]
    };

    lineOptions.value = {
        responsive: true,
        plugins: {
            legend: {
                labels: {
                    color: textColor
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
                    color: textColorSecondary
                },
                grid: {
                    color: surfaceBorder,
                    drawBorder: false
                }
            }
        }
    };

    // Polar Chart
    polarData.value = {
        datasets: [
            {
                data: [11, 16, 7, 3],
                backgroundColor: [primary500, primary400, primary300, primary200],
                borderColor: [primary500, primary400, primary300, primary200],
                borderWidth: 1,
                label: 'Distribución'
            }
        ],
        labels: ['Categoría A', 'Categoría B', 'Categoría C', 'Categoría D']
    };

    polarOptions.value = {
        responsive: true,
        plugins: {
            legend: {
                labels: {
                    color: textColor
                }
            }
        },
        scales: {
            r: {
                grid: {
                    color: surfaceBorder
                },
                ticks: {
                    color: textColorSecondary
                }
            }
        }
    };

    // Radar Chart
    radarData.value = {
        labels: ['Ingresos', 'Gastos', 'Ahorros', 'Inversiones', 'Deudas', 'Presupuesto', 'Metas'],
        datasets: [
            {
                label: 'Actual',
                borderColor: primary500,
                pointBackgroundColor: primary500,
                pointBorderColor: primary500,
                pointHoverBackgroundColor: textColor,
                pointHoverBorderColor: primary500,
                backgroundColor: primary500 + '20', // Agregar transparencia
                data: [65, 59, 90, 81, 56, 55, 40]
            },
            {
                label: 'Objetivo',
                borderColor: primary200,
                pointBackgroundColor: primary200,
                pointBorderColor: primary200,
                pointHoverBackgroundColor: textColor,
                pointHoverBorderColor: primary200,
                backgroundColor: primary200 + '20', // Agregar transparencia
                data: [28, 48, 40, 19, 96, 27, 100]
            }
        ]
    };

    radarOptions.value = {
        responsive: true,
        plugins: {
            legend: {
                labels: {
                    color: textColor
                }
            }
        },
        scales: {
            r: {
                grid: {
                    color: surfaceBorder
                },
                ticks: {
                    color: textColorSecondary
                }
            }
        }
    };

    // Forzar actualización de las gráficas
    nextTick(() => {
        refreshCharts();
    });
}

// Función para refrescar todas las gráficas
function refreshCharts() {
    const charts = [lineChart, barChart, pieChart, doughnutChart, polarChart, radarChart];
    
    charts.forEach(chartRef => {
        if (chartRef.value && chartRef.value.chart) {
            chartRef.value.chart.update();
        }
    });
}

// Watch mejorado que detecta cambios en el tema
watch(
    [() => UI.layoutConfig.primary, () => UI.layoutConfig.darkTheme, () => UI.layoutConfig.surface],
    () => {
        // Usar setTimeout para asegurar que las variables CSS estén actualizadas
        setTimeout(() => {
            setColorOptions();
        }, 100);
    },
    { immediate: true }
);

// También observar cambios en las variables CSS directamente
watch(
    () => UI.isDarkTheme,
    () => {
        setTimeout(() => {
            setColorOptions();
        }, 150);
    }
);
</script>

<template>
    <Fluid class="grid grid-cols-12 gap-8">
        <div class="col-span-12 xl:col-span-6">
            <div class="card backdrop-blur-sm bg-surface-0/80 dark:bg-surface-900/80 border border-surface-200/50 dark:border-surface-700/50">
                <div class="font-semibold text-xl mb-4 text-surface-900 dark:text-surface-0">Gráfica Lineal</div>
                <Chart ref="lineChart" type="line" :data="lineData" :options="lineOptions"></Chart>
            </div>
        </div>
        <div class="col-span-12 xl:col-span-6">
            <div class="card backdrop-blur-sm bg-surface-0/80 dark:bg-surface-900/80 border border-surface-200/50 dark:border-surface-700/50">
                <div class="font-semibold text-xl mb-4 text-surface-900 dark:text-surface-0">Gráfica de Barras</div>
                <Chart ref="barChart" type="bar" :data="barData" :options="barOptions"></Chart>
            </div>
        </div>
        <div class="col-span-12 xl:col-span-6">
            <div class="card backdrop-blur-sm bg-surface-0/80 dark:bg-surface-900/80 border border-surface-200/50 dark:border-surface-700/50 flex flex-col items-center">
                <div class="font-semibold text-xl mb-4 text-surface-900 dark:text-surface-0">Gráfica Circular</div>
                <Chart ref="pieChart" type="pie" :data="pieData" :options="pieOptions"></Chart>
            </div>
        </div>
        <div class="col-span-12 xl:col-span-6">
            <div class="card backdrop-blur-sm bg-surface-0/80 dark:bg-surface-900/80 border border-surface-200/50 dark:border-surface-700/50 flex flex-col items-center">
                <div class="font-semibold text-xl mb-4 text-surface-900 dark:text-surface-0">Gráfica Dona</div>
                <Chart ref="doughnutChart" type="doughnut" :data="pieData" :options="pieOptions"></Chart>
            </div>
        </div>
        <div class="col-span-12 xl:col-span-6">
            <div class="card backdrop-blur-sm bg-surface-0/80 dark:bg-surface-900/80 border border-surface-200/50 dark:border-surface-700/50 flex flex-col items-center">
                <div class="font-semibold text-xl mb-4 text-surface-900 dark:text-surface-0">Área Polar</div>
                <Chart ref="polarChart" type="polarArea" :data="polarData" :options="polarOptions"></Chart>
            </div>
        </div>
        <div class="col-span-12 xl:col-span-6">
            <div class="card backdrop-blur-sm bg-surface-0/80 dark:bg-surface-900/80 border border-surface-200/50 dark:border-surface-700/50 flex flex-col items-center">
                <div class="font-semibold text-xl mb-4 text-surface-900 dark:text-surface-0">Gráfica Radar</div>
                <Chart ref="radarChart" type="radar" :data="radarData" :options="radarOptions"></Chart>
            </div>
        </div>
    </Fluid>
</template>
