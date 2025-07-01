<template>
    <div class="credit-card-edit-tabs">
        <!-- Header con tabs -->
        <div class="mb-6">
            <div class="flex border-b border-surface-200 dark:border-surface-700">
                <button
                    v-for="tab in tabs"
                    :key="tab.value"
                    @click="setCurrentTab(tab.value)"
                    :class="[
                        'px-4 py-3 text-sm font-medium border-b-2 transition-colors duration-200',
                        currentTab === tab.value
                            ? 'border-primary-500 text-primary-600 dark:text-primary-400'
                            : 'border-transparent text-surface-500 hover:text-surface-700 hover:border-surface-300'
                    ]"
                >
                    <i :class="tab.icon" class="mr-2"></i>
                    {{ tab.label }}
                </button>
            </div>
        </div>

        <!-- Contenido de los tabs -->
        <div class="tab-content">
            <!-- Tab: Información General -->
            <div v-if="currentTab === 'general'" class="space-y-6">
                <h3 class="text-lg font-semibold text-surface-900 dark:text-surface-100 mb-4">
                    Información General
                </h3>
                
                <!-- Tipo de cuenta (readonly) -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div class="flex flex-col gap-2">
                        <label class="text-sm font-medium text-surface-600 dark:text-surface-400">
                            Tipo de Cuenta
                        </label>
                        <InputText
                            value="Tarjeta de Crédito"
                            readonly
                            class="bg-surface-50 dark:bg-surface-800"
                        />
                    </div>

                    <!-- Banco -->
                    <div class="flex flex-col gap-2">
                        <label class="text-sm font-medium text-surface-600 dark:text-surface-400">
                            Banco *
                        </label>
                        <Dropdown
                            v-model="accountForm.banco_id"
                            :options="banks"
                            option-label="nombre"
                            option-value="id"
                            placeholder="Selecciona un banco"
                            :loading="banksLoading"
                            :disabled="disabled"
                            :class="{ 'p-invalid': formErrors.banco_id }"
                        />
                        <small v-if="formErrors.banco_id" class="p-error">
                            {{ formErrors.banco_id }}
                        </small>
                    </div>
                </div>

                <!-- Nombre y nombre de tarjeta -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div class="flex flex-col gap-2">
                        <label class="text-sm font-medium text-surface-600 dark:text-surface-400">
                            Nombre de la Cuenta *
                        </label>
                        <InputText
                            v-model="accountForm.nombre"
                            :placeholder="namePlaceholder"
                            :disabled="disabled"
                            :class="{ 'p-invalid': formErrors.nombre }"
                        />
                        <small v-if="formErrors.nombre" class="p-error">
                            {{ formErrors.nombre }}
                        </small>
                    </div>

                    <div class="flex flex-col gap-2">
                        <label class="text-sm font-medium text-surface-600 dark:text-surface-400">
                            Nombre de la Tarjeta *
                        </label>
                        <InputText
                            v-model="accountForm.card_name"
                            placeholder="Ej: BBVA Oro, Santander Zero"
                            :disabled="disabled"
                            :class="{ 'p-invalid': formErrors.card_name }"
                        />
                        <small v-if="formErrors.card_name" class="p-error">
                            {{ formErrors.card_name }}
                        </small>
                    </div>
                </div>

                <!-- Últimos 4 dígitos -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div class="flex flex-col gap-2">
                        <label class="text-sm font-medium text-surface-600 dark:text-surface-400">
                            Últimos 4 Dígitos
                        </label>
                        <InputText
                            v-model="accountForm.last_four_digits"
                            placeholder="1234"
                            maxlength="4"
                            :disabled="disabled"
                            :class="{ 'p-invalid': formErrors.last_four_digits }"
                        />
                        <small v-if="formErrors.last_four_digits" class="p-error">
                            {{ formErrors.last_four_digits }}
                        </small>
                    </div>
                </div>
            </div>

            <!-- Tab: Configuración de Crédito -->
            <div v-if="currentTab === 'credit'" class="space-y-6">
                <h3 class="text-lg font-semibold text-surface-900 dark:text-surface-100 mb-4">
                    Configuración de Crédito
                </h3>

                <!-- Límite de crédito y crédito disponible -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div class="flex flex-col gap-2">
                        <label class="text-sm font-medium text-surface-600 dark:text-surface-400">
                            Límite de Crédito *
                        </label>
                        <InputNumber
                            v-model="accountForm.limite_credito"
                            mode="currency"
                            currency="MXN"
                            locale="es-MX"
                            :min="0"
                            :disabled="disabled"
                            :class="{ 'p-invalid': formErrors.limite_credito }"
                        />
                        <small v-if="formErrors.limite_credito" class="p-error">
                            {{ formErrors.limite_credito }}
                        </small>
                    </div>

                    <div class="flex flex-col gap-2">
                        <label class="text-sm font-medium text-surface-600 dark:text-surface-400">
                            Crédito Disponible *
                        </label>
                        <InputNumber
                            v-model="accountForm.credito_disponible"
                            mode="currency"
                            currency="MXN"
                            locale="es-MX"
                            :min="0"
                            :max="accountForm.limite_credito"
                            :disabled="disabled"
                            :class="{ 'p-invalid': formErrors.credito_disponible }"
                        />
                        <small v-if="formErrors.credito_disponible" class="p-error">
                            {{ formErrors.credito_disponible }}
                        </small>
                    </div>
                </div>

                <!-- Fechas de pago y corte -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div class="flex flex-col gap-2">
                        <label class="text-sm font-medium text-surface-600 dark:text-surface-400">
                            Día de Pago *
                        </label>
                        <InputNumber
                            v-model="accountForm.dia_pago"
                            :min="1"
                            :max="31"
                            :disabled="disabled"
                            :class="{ 'p-invalid': formErrors.dia_pago }"
                        />
                        <small v-if="formErrors.dia_pago" class="p-error">
                            {{ formErrors.dia_pago }}
                        </small>
                    </div>

                    <div class="flex flex-col gap-2">
                        <label class="text-sm font-medium text-surface-600 dark:text-surface-400">
                            Día de Corte *
                        </label>
                        <InputNumber
                            v-model="accountForm.dia_corte"
                            :min="1"
                            :max="31"
                            :disabled="disabled"
                            :class="{ 'p-invalid': formErrors.dia_corte }"
                        />
                        <small v-if="formErrors.dia_corte" class="p-error">
                            {{ formErrors.dia_corte }}
                        </small>
                    </div>
                </div>

                <!-- Tasa de interés y porcentaje mínimo -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div class="flex flex-col gap-2">
                        <label class="text-sm font-medium text-surface-600 dark:text-surface-400">
                            Tasa de Interés Anual (%)
                        </label>
                        <InputNumber
                            v-model="accountForm.interest_rate"
                            mode="decimal"
                            :min="0"
                            :max="100"
                            :min-fraction-digits="2"
                            :max-fraction-digits="2"
                            :disabled="disabled"
                            suffix="%"
                            :class="{ 'p-invalid': formErrors.interest_rate }"
                        />
                        <small v-if="formErrors.interest_rate" class="p-error">
                            {{ formErrors.interest_rate }}
                        </small>
                    </div>

                    <div class="flex flex-col gap-2">
                        <label class="text-sm font-medium text-surface-600 dark:text-surface-400">
                            Pago Mínimo (%)
                        </label>
                        <InputNumber
                            v-model="accountForm.min_payment_percent"
                            mode="decimal"
                            :min="1"
                            :max="100"
                            :min-fraction-digits="2"
                            :max-fraction-digits="2"
                            :disabled="disabled"
                            suffix="%"
                            :class="{ 'p-invalid': formErrors.min_payment_percent }"
                        />
                        <small v-if="formErrors.min_payment_percent" class="p-error">
                            {{ formErrors.min_payment_percent }}
                        </small>
                    </div>
                </div>
            </div>

            <!-- Tab: Costos y Comisiones -->
            <div v-if="currentTab === 'costs'" class="space-y-6">
                <h3 class="text-lg font-semibold text-surface-900 dark:text-surface-100 mb-4">
                    Costos y Comisiones
                </h3>

                <!-- CAT y Anualidad -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div class="flex flex-col gap-2">
                        <label class="text-sm font-medium text-surface-600 dark:text-surface-400">
                            CAT (Costo Anual Total) %
                        </label>
                        <InputNumber
                            v-model="accountForm.cat_percentage"
                            mode="decimal"
                            :min="0"
                            :max="200"
                            :min-fraction-digits="2"
                            :max-fraction-digits="2"
                            :disabled="disabled"
                            suffix="%"
                            :class="{ 'p-invalid': formErrors.cat_percentage }"
                        />
                        <small v-if="formErrors.cat_percentage" class="p-error">
                            {{ formErrors.cat_percentage }}
                        </small>
                    </div>

                    <div class="flex flex-col gap-2">
                        <label class="text-sm font-medium text-surface-600 dark:text-surface-400">
                            Anualidad
                        </label>
                        <InputNumber
                            v-model="accountForm.annual_fee"
                            mode="currency"
                            currency="MXN"
                            locale="es-MX"
                            :min="0"
                            :disabled="disabled"
                            :class="{ 'p-invalid': formErrors.annual_fee }"
                        />
                        <small v-if="formErrors.annual_fee" class="p-error">
                            {{ formErrors.annual_fee }}
                        </small>
                    </div>
                </div>

                <!-- Gasto para exentar anualidad y días de gracia -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div class="flex flex-col gap-2">
                        <label class="text-sm font-medium text-surface-600 dark:text-surface-400">
                            Gasto para Exentar Anualidad
                        </label>
                        <InputNumber
                            v-model="accountForm.annual_fee_waiver_spending"
                            mode="currency"
                            currency="MXN"
                            locale="es-MX"
                            :min="0"
                            :disabled="disabled"
                            :class="{ 'p-invalid': formErrors.annual_fee_waiver_spending }"
                        />
                        <small v-if="formErrors.annual_fee_waiver_spending" class="p-error">
                            {{ formErrors.annual_fee_waiver_spending }}
                        </small>
                    </div>

                    <div class="flex flex-col gap-2">
                        <label class="text-sm font-medium text-surface-600 dark:text-surface-400">
                            Días de Gracia
                        </label>
                        <InputNumber
                            v-model="accountForm.grace_period_days"
                            :min="0"
                            :max="60"
                            :disabled="disabled"
                            suffix=" días"
                            :class="{ 'p-invalid': formErrors.grace_period_days }"
                        />
                        <small v-if="formErrors.grace_period_days" class="p-error">
                            {{ formErrors.grace_period_days }}
                        </small>
                    </div>
                </div>
            </div>

            <!-- Tab: Beneficios -->
            <div v-if="currentTab === 'benefits'" class="space-y-6">
                <h3 class="text-lg font-semibold text-surface-900 dark:text-surface-100 mb-4">
                    Beneficios y Recompensas
                </h3>

                <!-- Cashback y puntos -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div class="flex flex-col gap-2">
                        <label class="text-sm font-medium text-surface-600 dark:text-surface-400">
                            Cashback (%)
                        </label>
                        <InputNumber
                            v-model="accountForm.cashback_percentage"
                            mode="decimal"
                            :min="0"
                            :max="100"
                            :min-fraction-digits="2"
                            :max-fraction-digits="2"
                            :disabled="disabled"
                            suffix="%"
                            :class="{ 'p-invalid': formErrors.cashback_percentage }"
                        />
                        <small v-if="formErrors.cashback_percentage" class="p-error">
                            {{ formErrors.cashback_percentage }}
                        </small>
                    </div>

                    <div class="flex flex-col gap-2">
                        <label class="text-sm font-medium text-surface-600 dark:text-surface-400">
                            Puntos por Peso
                        </label>
                        <InputNumber
                            v-model="accountForm.rewards_points_ratio"
                            mode="decimal"
                            :min="0"
                            :min-fraction-digits="2"
                            :max-fraction-digits="4"
                            :disabled="disabled"
                            :class="{ 'p-invalid': formErrors.rewards_points_ratio }"
                        />
                        <small v-if="formErrors.rewards_points_ratio" class="p-error">
                            {{ formErrors.rewards_points_ratio }}
                        </small>
                    </div>
                </div>

                <!-- Notas adicionales -->
                <div class="flex flex-col gap-2">
                    <label class="text-sm font-medium text-surface-600 dark:text-surface-400">
                        Notas Adicionales
                    </label>
                    <Textarea
                        v-model="accountForm.notes"
                        placeholder="Promociones, beneficios especiales, MSI, etc..."
                        rows="4"
                        :disabled="disabled"
                        :class="{ 'p-invalid': formErrors.notes }"
                    />
                    <small v-if="formErrors.notes" class="p-error">
                        {{ formErrors.notes }}
                    </small>
                </div>
            </div>
        </div>

        <!-- Botones de acción -->
        <div class="flex justify-end gap-3 mt-8 pt-6 border-t border-surface-200 dark:border-surface-700">
            <Button
                label="Cancelar"
                severity="secondary"
                @click="$emit('cancel')"
                :disabled="isSubmitting"
            />
            <Button
                label="Actualizar Tarjeta"
                @click="$emit('submit')"
                :loading="isSubmitting"
                :disabled="!isFormValid"
            />
        </div>
    </div>
</template>

<script setup>
import { computed } from 'vue';

// Props
const props = defineProps({
    accountForm: {
        type: Object,
        required: true
    },
    formErrors: {
        type: Object,
        default: () => ({})
    },
    banks: {
        type: Array,
        default: () => []
    },
    banksLoading: {
        type: Boolean,
        default: false
    },
    disabled: {
        type: Boolean,
        default: false
    },
    isSubmitting: {
        type: Boolean,
        default: false
    },
    isFormValid: {
        type: Boolean,
        default: false
    },
    currentTab: {
        type: String,
        default: 'general'
    },
    namePlaceholder: {
        type: String,
        default: 'Ej: Tarjeta BBVA Oro'
    }
});

// Emits
const emit = defineEmits(['submit', 'cancel', 'update:currentTab']);

// Tabs configuration
const tabs = [
    {
        value: 'general',
        label: 'General',
        icon: 'pi pi-id-card'
    },
    {
        value: 'credit',
        label: 'Crédito',
        icon: 'pi pi-credit-card'
    },
    {
        value: 'costs',
        label: 'Costos',
        icon: 'pi pi-dollar'
    },
    {
        value: 'benefits',
        label: 'Beneficios',
        icon: 'pi pi-star'
    }
];

// Funciones
const setCurrentTab = (tab) => {
    emit('update:currentTab', tab);
};
</script>

<style lang="scss" scoped>
.credit-card-edit-tabs {
    .tab-content {
        min-height: 400px;
    }
}

.p-error {
    color: #e24c4c;
}
</style>
