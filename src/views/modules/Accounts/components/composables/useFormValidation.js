import { computed } from 'vue';

export function useFormValidation(accountForm, formErrors, needsBankSelection) {
    
    const isFormValid = computed(() => {
        const form = accountForm.value;

        // Validaciones básicas
        if (!form.name?.trim()) {
            console.log('❌ Form invalid: missing name');
            return false;
        }
        
        if (needsBankSelection.value && !form.bank_id) {
            console.log('❌ Form invalid: missing bank');
            return false;
        }

        // Validaciones específicas para tarjeta de crédito
        if (form.type === 'credit_card') {
            const creditLimit = Number(form.credit_limit);
            const paymentDay = Number(form.payment_day);
            const cutoffDay = Number(form.cutoff_day);
            
            if (!creditLimit || creditLimit <= 0) {
                console.log('❌ Form invalid: invalid credit limit');
                return false;
            }
            if (!paymentDay || paymentDay < 1 || paymentDay > 31) {
                console.log('❌ Form invalid: invalid payment day');
                return false;
            }
            if (!cutoffDay || cutoffDay < 1 || cutoffDay > 31) {
                console.log('❌ Form invalid: invalid cutoff day');
                return false;
            }
        }

        // Verificar que no hay errores de validación críticos
        const criticalErrors = Object.keys(formErrors.value).filter(key => 
            !['cat_percentage', 'annual_fee', 'cashback_percentage', 'rewards_points_ratio', 'grace_period_days'].includes(key)
        );
        
        const isValid = criticalErrors.length === 0;
        console.log('✅ Form validation result:', {
            isValid,
            criticalErrors,
            allErrors: formErrors.value
        });
        
        return isValid;
    });

    const validateForm = () => {
        const errors = {};
        const form = accountForm.value;

        console.log('🔍 Validando formulario:', form);

        // Validar nombre
        if (!form.name?.trim()) {
            errors.name = 'El nombre es requerido';
        } else if (form.name.trim().length < 2) {
            errors.name = 'El nombre debe tener al menos 2 caracteres';
        } else if (form.name.trim().length > 100) {
            errors.name = 'El nombre no puede exceder 100 caracteres';
        }

        // Validar banco (si es requerido)
        if (needsBankSelection.value && !form.bank_id) {
            errors.bank_id = 'Debe seleccionar un banco';
        }

        // Validaciones específicas para tarjeta de crédito
        if (form.type === 'credit_card') {
            if (!form.credit_limit || Number(form.credit_limit) <= 0) {
                errors.credit_limit = 'El límite de crédito debe ser mayor a 0';
            }

            const paymentDay = Number(form.payment_day);
            if (!paymentDay || paymentDay < 1 || paymentDay > 31) {
                errors.payment_day = 'El día de pago debe estar entre 1 y 31';
            }

            const cutoffDay = Number(form.cutoff_day);
            if (!cutoffDay || cutoffDay < 1 || cutoffDay > 31) {
                errors.cutoff_day = 'El día de corte debe estar entre 1 y 31';
            }
        }

        formErrors.value = errors;
        console.log('🔍 Errores de validación:', errors);
        return Object.keys(errors).length === 0;
    };

    // Validaciones específicas para steps
    const canProceedFromStep1 = computed(() => {
        const form = accountForm.value;
        const isValid = !!(form.bank_id && form.name?.trim());
        console.log('🔍 Validando Step 1:', {
            bank_id: form.bank_id,
            name: form.name?.trim(),
            canProceed: isValid
        });
        return isValid;
    });

    const canProceedFromStep2 = computed(() => {
        const form = accountForm.value;
        const creditLimit = Number(form.credit_limit);
        const paymentDay = Number(form.payment_day);
        const cutoffDay = Number(form.cutoff_day);
        
        const isValid = creditLimit > 0 && 
               paymentDay >= 1 && paymentDay <= 31 && 
               cutoffDay >= 1 && cutoffDay <= 31;
        
        console.log('🔍 Validando Step 2:', {
            credit_limit: creditLimit,
            payment_day: paymentDay,
            cutoff_day: cutoffDay,
            canProceed: isValid
        });
        
        return isValid;
    });

    const validateStep = (stepNumber) => {
        const currentErrors = { ...formErrors.value };
        
        if (stepNumber === 1) {
            // Limpiar errores del step 1
            delete currentErrors.bank_id;
            delete currentErrors.name;
            
            if (!accountForm.value.bank_id) {
                currentErrors.bank_id = 'Debe seleccionar un banco';
            }
            
            if (!accountForm.value.name?.trim()) {
                currentErrors.name = 'El nombre es requerido';
            }
            
        } else if (stepNumber === 2) {
            // Limpiar errores del step 2
            delete currentErrors.credit_limit;
            delete currentErrors.payment_day;
            delete currentErrors.cutoff_day;
            
            const creditLimit = Number(accountForm.value.credit_limit);
            const paymentDay = Number(accountForm.value.payment_day);
            const cutoffDay = Number(accountForm.value.cutoff_day);
            
            if (!creditLimit || creditLimit <= 0) {
                currentErrors.credit_limit = 'El límite de crédito debe ser mayor a 0';
            }
            
            if (!paymentDay || paymentDay < 1 || paymentDay > 31) {
                currentErrors.payment_day = 'El día de pago debe estar entre 1 y 31';
            }
            
            if (!cutoffDay || cutoffDay < 1 || cutoffDay > 31) {
                currentErrors.cutoff_day = 'El día de corte debe estar entre 1 y 31';
            }
        }
        
        formErrors.value = currentErrors;
        
        // Retornar si el step es válido
        if (stepNumber === 1) return canProceedFromStep1.value;
        if (stepNumber === 2) return canProceedFromStep2.value;
        return true; // Steps 3 y 4 son opcionales
    };

    return {
        isFormValid,
        validateForm,
        canProceedFromStep1,
        canProceedFromStep2,
        validateStep
    };
}
