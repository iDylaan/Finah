/**
 * Utilidades para manejo de tarjetas de crédito
 * Cálculos de periodos, fechas de corte, pagos y saldos
 */

import { diasHasta } from '@/lib/utils.js';

/**
 * Calcula la próxima fecha de un día específico del mes
 * @param {number} diaDelMes - Día del mes (1-31)
 * @param {Date} [desde] - Fecha desde la cual calcular (default: hoy)
 * @returns {Date} - Próxima fecha que coincide con ese día
 */
export const calcularProximaFecha = (diaDelMes, desde = new Date()) => {
    const hoy = new Date(desde);
    hoy.setHours(12, 0, 0, 0); // Mediodía para evitar problemas de zona horaria
    
    const año = hoy.getFullYear();
    const mes = hoy.getMonth();
    
    // Primera opción: ese día en el mes actual
    let proximaFecha = new Date(año, mes, diaDelMes, 12, 0, 0, 0);
    
    // Si ya pasó, usar el mes siguiente
    if (proximaFecha <= hoy) {
        proximaFecha = new Date(año, mes + 1, diaDelMes, 12, 0, 0, 0);
    }
    
    return proximaFecha;
};

/**
 * Calcula la fecha de corte anterior más cercana
 * @param {number} diaCorte - Día del mes de corte
 * @param {Date} [desde] - Fecha de referencia (default: hoy)
 * @returns {Date} - Fecha del último corte
 */
export const calcularUltimoCorte = (diaCorte, desde = new Date()) => {
    const hoy = new Date(desde);
    hoy.setHours(12, 0, 0, 0);
    
    const año = hoy.getFullYear();
    const mes = hoy.getMonth();
    
    // Primera opción: ese día en el mes actual
    let fechaCorte = new Date(año, mes, diaCorte, 12, 0, 0, 0);
    
    // Si aún no ha llegado el corte de este mes, usar el mes anterior
    if (fechaCorte > hoy) {
        fechaCorte = new Date(año, mes - 1, diaCorte, 12, 0, 0, 0);
    }
    
    return fechaCorte;
};

/**
 * Calcula el periodo actual de la tarjeta de crédito
 * @param {number} diaCorte - Día del mes de corte
 * @param {Date} [desde] - Fecha de referencia (default: hoy)
 * @returns {Object} - { inicioCorte: Date, finCorte: Date, proximoPago: Date }
 */
export const calcularPeriodoActual = (diaCorte, diaPago, desde = new Date()) => {
    const fechaCorteAnterior = calcularUltimoCorte(diaCorte, desde);
    const proximoCorte = calcularProximaFecha(diaCorte, desde);
    const proximoPago = calcularProximaFecha(diaPago, desde);
    
    return {
        inicioCorte: fechaCorteAnterior,
        finCorte: proximoCorte,
        proximoPago: proximoPago
    };
};

/**
 * Calcula el porcentaje de uso del crédito
 * @param {number} limiteCredito - Límite total de la tarjeta
 * @param {number} creditoDisponible - Crédito disponible actual
 * @returns {number} - Porcentaje usado (0-100)
 */
export const porcentajeUsoCredito = (limiteCredito, creditoDisponible) => {
    if (!limiteCredito || limiteCredito <= 0) return 0;
    
    // Asegurar que creditoDisponible sea un número válido
    const disponible = parseFloat(creditoDisponible) || 0;
    const limite = parseFloat(limiteCredito) || 0;
    
    const usado = limite - disponible;
    const porcentaje = (usado / limite) * 100;
    
    return Math.max(0, Math.min(100, porcentaje));
};

/**
 * Calcula el monto usado del crédito
 * @param {number} limiteCredito - Límite total de la tarjeta
 * @param {number} creditoDisponible - Crédito disponible actual
 * @returns {number} - Monto usado
 */
export const montoUsado = (limiteCredito, creditoDisponible) => {
    if (!limiteCredito) return 0;
    const limite = parseFloat(limiteCredito) || 0;
    const disponible = parseFloat(creditoDisponible) || 0;
    return Math.max(0, limite - disponible);
};

/**
 * Calcula el pago mínimo basado en el saldo y porcentaje
 * @param {number} saldoActual - Saldo total a pagar
 * @param {number} porcentajePagoMinimo - Porcentaje del pago mínimo (default: 5%)
 * @returns {number} - Monto del pago mínimo
 */
export const calcularPagoMinimo = (saldoActual, porcentajePagoMinimo = 5) => {
    if (!saldoActual || saldoActual <= 0) return 0;
    
    const pagoMinimo = (saldoActual * porcentajePagoMinimo) / 100;
    
    // Mínimo $50 o 5% del saldo (lo que sea mayor)
    return Math.max(50, pagoMinimo);
};

/**
 * Determina el nivel de severidad según días restantes
 * @param {number} diasRestantes - Días hasta la fecha límite
 * @returns {string} - Severidad: 'peligro', 'advertencia', 'informacion'
 */
export const obtenerSeveridadPorDias = (diasRestantes) => {
    if (diasRestantes === null || diasRestantes === undefined) return 'secundario';
    
    if (diasRestantes < 0) return 'peligro';      // Ya pasó
    if (diasRestantes === 0) return 'peligro';     // Hoy
    if (diasRestantes <= 3) return 'advertencia';  // 1-3 días
    if (diasRestantes <= 7) return 'informacion';  // 4-7 días
    
    return 'secundario'; // Más de 7 días
};

/**
 * Determina el nivel de severidad según porcentaje de uso
 * @param {number} porcentajeUso - Porcentaje de crédito usado (0-100)
 * @returns {string} - Severidad: 'peligro', 'advertencia', 'exito'
 */
export const obtenerSeveridadPorUso = (porcentajeUso) => {
    if (porcentajeUso >= 90) return 'peligro';      // 90-100%
    if (porcentajeUso >= 70) return 'advertencia';  // 70-89%
    if (porcentajeUso >= 50) return 'informacion';  // 50-69%
    
    return 'exito'; // 0-49%
};

/**
 * Formatea un monto como moneda MXN
 * @param {number} monto - Monto a formatear
 * @returns {string} - Monto formateado
 */
export const formatearMoneda = (monto) => {
    if (monto === null || monto === undefined) return '$0.00';
    
    return new Intl.NumberFormat('es-MX', {
        style: 'currency',
        currency: 'MXN'
    }).format(monto);
};

/**
 * Genera un mensaje descriptivo del estado del pago
 * @param {number} diasHastaPago - Días hasta la fecha de pago
 * @returns {string} - Mensaje descriptivo
 */
export const obtenerMensajePago = (diasHastaPago) => {
    if (diasHastaPago === null || diasHastaPago === undefined) return '';
    
    if (diasHastaPago < 0) return '¡Pago vencido!';
    if (diasHastaPago === 0) return '¡Pago hoy!';
    if (diasHastaPago === 1) return 'Pago mañana';
    if (diasHastaPago <= 3) return `Pago en ${diasHastaPago} días`;
    if (diasHastaPago <= 7) return `Pago en ${diasHastaPago} días`;
    
    return `${diasHastaPago} días para el pago`;
};

/**
 * Genera un mensaje descriptivo del estado del corte
 * @param {number} diasHastaCorte - Días hasta la fecha de corte
 * @returns {string} - Mensaje descriptivo
 */
export const obtenerMensajeCorte = (diasHastaCorte) => {
    if (diasHastaCorte === null || diasHastaCorte === undefined) return '';
    
    if (diasHastaCorte < 0) return 'Periodo cerrado';
    if (diasHastaCorte === 0) return '¡Corte hoy!';
    if (diasHastaCorte === 1) return 'Corte mañana';
    if (diasHastaCorte <= 3) return `Corte en ${diasHastaCorte} días`;
    if (diasHastaCorte <= 7) return `Corte en ${diasHastaCorte} días`;
    
    return `${diasHastaCorte} días para el corte`;
};
