import { ref } from 'vue';

export function useCreditCardSteps() {
    
    const currentStepValue = ref('1');
    const currentEditTab = ref('general');

    // Configuración de tabs para editar tarjeta de crédito
    const editTabs = ref([
        { id: 'general', title: 'General', icon: 'pi pi-info-circle' },
        { id: 'credit', title: 'Crédito', icon: 'pi pi-credit-card' },
        { id: 'costs', title: 'Costos', icon: 'pi pi-dollar' },
        { id: 'benefits', title: 'Beneficios', icon: 'pi pi-star' }
    ]);

    // Funciones para navegación de steps
    const validateAndProceedToStep = (targetStep, activateCallback, validateStepFn) => {
        console.log(`🔄 Intentando avanzar al step ${targetStep}`);
        
        const currentStep = parseInt(targetStep) - 1;
        
        if (currentStep === 1) {
            // Validar Step 1
            const isValid = validateStepFn(1);
            if (isValid) {
                activateCallback(targetStep);
            } else {
                console.warn('⚠️ No se puede avanzar del Step 1 - faltan datos requeridos');
            }
        } else if (currentStep === 2) {
            // Validar Step 2
            const isValid = validateStepFn(2);
            if (isValid) {
                activateCallback(targetStep);
            } else {
                console.warn('⚠️ No se puede avanzar del Step 2 - faltan datos requeridos');
            }
        } else {
            // Para steps 3 y 4 (opcionales), avanzar directamente
            activateCallback(targetStep);
        }
    };

    const goToPreviousStep = (targetStep, activateCallback, clearErrorsFn) => {
        console.log(`⬅️ Regresando al step ${targetStep}`);
        // Limpiar errores al retroceder
        clearErrorsFn();
        activateCallback(targetStep);
    };

    const resetSteps = () => {
        currentStepValue.value = '1';
        currentEditTab.value = 'general';
    };

    const setCurrentStep = (step) => {
        currentStepValue.value = step.toString();
    };

    const setCurrentTab = (tab) => {
        currentEditTab.value = tab;
    };

    return {
        // Estado
        currentStepValue,
        currentEditTab,
        editTabs,
        
        // Funciones
        validateAndProceedToStep,
        goToPreviousStep,
        resetSteps,
        setCurrentStep,
        setCurrentTab
    };
}
