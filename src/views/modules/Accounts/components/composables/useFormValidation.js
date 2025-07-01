import { computed } from 'vue';

export function useFormValidation(accountForm, formErrors, needsBankSelection) {
    
    const isFormValid = computed(() => {
        const form = accountForm.value;

        // Validaciones básicas
        if (!form.name?.trim()) {
            console.log('❌ Form invalid: missing name');
            return false;
        }
        
        if (needsBankSelection.value && !form.banco_id) {
            console.log('❌ Form invalid: missing bank');
            return false;
        }

        // Validaciones específicas para tarjeta de crédito
        if (form.type === 'credit_card') {
            const creditLimit = Number(form.limite_credito);
            const paymentDay = Number(form.dia_pago);
            const cutoffDay = Number(form.dia_corte);
            
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
            !['porcentaje_cat', 'anualidad', 'porcentaje_cashback', 'ratio_puntos_recompensa', 'dias_periodo_gracia'].includes(key)
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
        if (needsBankSelection.value && !form.banco_id) {
            errors.banco_id = 'Debe seleccionar un banco';
        }

        // Validaciones específicas para tarjeta de crédito
        if (form.type === 'credit_card') {
            if (!form.limite_credito || Number(form.limite_credito) <= 0) {
                errors.limite_credito = 'El límite de crédito debe ser mayor a 0';
            }

            const paymentDay = Number(form.dia_pago);
            if (!paymentDay || paymentDay < 1 || paymentDay > 31) {
                errors.dia_pago = 'El día de pago debe estar entre 1 y 31';
            }

            const cutoffDay = Number(form.dia_corte);
            if (!cutoffDay || cutoffDay < 1 || cutoffDay > 31) {
                errors.dia_corte = 'El día de corte debe estar entre 1 y 31';
            }
        }

        formErrors.value = errors;
        console.log('🔍 Errores de validación:', errors);
        return Object.keys(errors).length === 0;
    };

    // Validaciones específicas para steps
    const canProceedFromStep1 = computed(() => {
        const form = accountForm.value;
        const isValid = !!(form.banco_id && form.name?.trim());
        console.log('🔍 Validando Step 1:', {
            banco_id: form.banco_id,
            name: form.name?.trim(),
            canProceed: isValid
        });
        return isValid;
    });

    const canProceedFromStep2 = computed(() => {
        const form = accountForm.value;
        const creditLimit = Number(form.limite_credito);
        const paymentDay = Number(form.dia_pago);
        const cutoffDay = Number(form.dia_corte);
        
        const isValid = creditLimit > 0 && 
               paymentDay >= 1 && paymentDay <= 31 && 
               cutoffDay >= 1 && cutoffDay <= 31;
        
        console.log('🔍 Validando Step 2:', {
            limite_credito: creditLimit,
            dia_pago: paymentDay,
            dia_corte: cutoffDay,
            canProceed: isValid
        });
        
        return isValid;
    });

    const validateStep = (stepNumber) => {
        const currentErrors = { ...formErrors.value };
        
        if (stepNumber === 1) {
            // Limpiar errores del step 1
            delete currentErrors.banco_id;
            delete currentErrors.name;
            
            if (!accountForm.value.banco_id) {
                currentErrors.banco_id = 'Debe seleccionar un banco';
            }
            
            if (!accountForm.value.name?.trim()) {
                currentErrors.name = 'El nombre es requerido';
            }
            
        } else if (stepNumber === 2) {
            // Limpiar errores del step 2
            delete currentErrors.limite_credito;
            delete currentErrors.dia_pago;
            delete currentErrors.dia_corte;
            
            const creditLimit = Number(accountForm.value.limite_credito);
            const paymentDay = Number(accountForm.value.dia_pago);
            const cutoffDay = Number(accountForm.value.dia_corte);
            
            if (!creditLimit || creditLimit <= 0) {
                currentErrors.limite_credito = 'El límite de crédito debe ser mayor a 0';
            }
            
            if (!paymentDay || paymentDay < 1 || paymentDay > 31) {
                currentErrors.dia_pago = 'El día de pago debe estar entre 1 y 31';
            }
            
            if (!cutoffDay || cutoffDay < 1 || cutoffDay > 31) {
                currentErrors.dia_corte = 'El día de corte debe estar entre 1 y 31';
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
