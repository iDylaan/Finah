/**
 * Utilidades misceláneas para cálculos de fechas y operaciones comunes
 * Funciones reutilizables en toda la aplicación
 */

/**
 * Calcula los días restantes hasta una fecha
 * @param {Date|string} fecha - Fecha objetivo
 * @returns {number} - Días restantes (puede ser negativo si ya pasó)
 */
export const diasHasta = (fecha) => {
    if (!fecha) return null;
    
    const hoy = new Date();
    hoy.setHours(0, 0, 0, 0);
    
    let fechaObj;
    if (typeof fecha === 'string') {
        // Si es formato YYYY-MM-DD, parsearlo en zona local
        if (/^\d{4}-\d{2}-\d{2}/.test(fecha)) {
            const [year, month, day] = fecha.split('T')[0].split('-').map(Number);
            fechaObj = new Date(year, month - 1, day);
        } else {
            fechaObj = new Date(fecha);
        }
    } else {
        fechaObj = new Date(fecha);
    }
    
    fechaObj.setHours(0, 0, 0, 0);
    
    const diffTime = fechaObj - hoy;
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    
    return diffDays;
};

/**
 * Calcula los días transcurridos desde una fecha
 * @param {Date|string} fecha - Fecha de inicio
 * @returns {number} - Días transcurridos (positivo si ya pasó)
 */
export const diasDesde = (fecha) => {
    if (!fecha) return null;
    
    const dias = diasHasta(fecha);
    return dias !== null ? -dias : null;
};

/**
 * Verifica si una fecha es hoy
 * @param {Date|string} fecha - Fecha a verificar
 * @returns {boolean} - True si es hoy
 */
export const esHoy = (fecha) => {
    return diasHasta(fecha) === 0;
};

/**
 * Verifica si una fecha es mañana
 * @param {Date|string} fecha - Fecha a verificar
 * @returns {boolean} - True si es mañana
 */
export const esManana = (fecha) => {
    return diasHasta(fecha) === 1;
};

/**
 * Verifica si una fecha está en el pasado
 * @param {Date|string} fecha - Fecha a verificar
 * @returns {boolean} - True si ya pasó
 */
export const esPasado = (fecha) => {
    const dias = diasHasta(fecha);
    return dias !== null && dias < 0;
};

/**
 * Verifica si una fecha está en el futuro
 * @param {Date|string} fecha - Fecha a verificar
 * @returns {boolean} - True si está por venir
 */
export const esFuturo = (fecha) => {
    const dias = diasHasta(fecha);
    return dias !== null && dias > 0;
};

/**
 * Calcula la diferencia en días entre dos fechas
 * @param {Date|string} fechaInicio - Fecha de inicio
 * @param {Date|string} fechaFin - Fecha de fin
 * @returns {number} - Diferencia en días (positivo si fechaFin > fechaInicio)
 */
export const diferenciaEnDias = (fechaInicio, fechaFin) => {
    if (!fechaInicio || !fechaFin) return null;
    
    const parseDate = (fecha) => {
        if (typeof fecha === 'string') {
            if (/^\d{4}-\d{2}-\d{2}/.test(fecha)) {
                const [year, month, day] = fecha.split('T')[0].split('-').map(Number);
                return new Date(year, month - 1, day);
            }
            return new Date(fecha);
        }
        return new Date(fecha);
    };
    
    const inicio = parseDate(fechaInicio);
    const fin = parseDate(fechaFin);
    
    inicio.setHours(0, 0, 0, 0);
    fin.setHours(0, 0, 0, 0);
    
    const diffTime = fin - inicio;
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
};

/**
 * Agrega días a una fecha
 * @param {Date|string} fecha - Fecha base
 * @param {number} dias - Número de días a agregar (puede ser negativo)
 * @returns {Date} - Nueva fecha
 */
export const agregarDias = (fecha, dias) => {
    if (!fecha) return null;
    
    const parseDate = (f) => {
        if (typeof f === 'string') {
            if (/^\d{4}-\d{2}-\d{2}/.test(f)) {
                const [year, month, day] = f.split('T')[0].split('-').map(Number);
                return new Date(year, month - 1, day);
            }
            return new Date(f);
        }
        return new Date(f);
    };
    
    const fechaObj = parseDate(fecha);
    fechaObj.setDate(fechaObj.getDate() + dias);
    
    return fechaObj;
};

/**
 * Obtiene el primer día del mes actual
 * @param {Date|string} [fecha] - Fecha de referencia (default: hoy)
 * @returns {Date} - Primer día del mes
 */
export const primerDiaDelMes = (fecha = new Date()) => {
    const fechaObj = typeof fecha === 'string' ? new Date(fecha) : new Date(fecha);
    return new Date(fechaObj.getFullYear(), fechaObj.getMonth(), 1);
};

/**
 * Obtiene el último día del mes actual
 * @param {Date|string} [fecha] - Fecha de referencia (default: hoy)
 * @returns {Date} - Último día del mes
 */
export const ultimoDiaDelMes = (fecha = new Date()) => {
    const fechaObj = typeof fecha === 'string' ? new Date(fecha) : new Date(fecha);
    return new Date(fechaObj.getFullYear(), fechaObj.getMonth() + 1, 0);
};

/**
 * Formatea un número como moneda MXN
 * @param {number} monto - Monto a formatear
 * @param {boolean} sinDecimales - Si debe omitir los decimales
 * @returns {string} - Monto formateado
 */
export const formatCurrency = (monto, sinDecimales = false) => {
    if (monto === null || monto === undefined) return '$0.00';
    
    return new Intl.NumberFormat('es-MX', {
        style: 'currency',
        currency: 'MXN',
        minimumFractionDigits: sinDecimales ? 0 : 2,
        maximumFractionDigits: sinDecimales ? 0 : 2
    }).format(monto);
};

/**
 * Formatea un número con separadores de miles
 * @param {number} numero - Número a formatear
 * @param {number} decimales - Número de decimales (default: 0)
 * @returns {string} - Número formateado
 */
export const formatNumber = (numero, decimales = 0) => {
    if (numero === null || numero === undefined) return '0';
    
    return new Intl.NumberFormat('es-MX', {
        minimumFractionDigits: decimales,
        maximumFractionDigits: decimales
    }).format(numero);
};
