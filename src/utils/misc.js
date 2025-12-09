/**
 * @deprecated Este archivo está deprecado. 
 * Todas las funciones se han movido a @/lib/utils.js
 * Este archivo solo reexporta las funciones para mantener compatibilidad con código legacy.
 * Por favor, actualiza tus imports a: import { ... } from '@/lib/utils.js'
 */

export {
    diasHasta,
    diasDesde,
    esHoy,
    esManana,
    esPasado,
    esFuturo,
    diferenciaEnDias,
    agregarDias,
    primerDiaDelMes,
    ultimoDiaDelMes,
    formatCurrency,
    formatNumber
} from '@/lib/utils.js';
