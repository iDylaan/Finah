export const LEVEL_COLORS = {
    // Azules
    blue: 'blue',
    indigo: 'indigo',
    cyan: 'cyan',
    sky: 'sky',

    // Verdes
    green: 'green',
    emerald: 'emerald',
    teal: 'teal',
    lime: 'lime',

    // Rojos y rosas
    red: 'red',
    rose: 'rose',
    pink: 'pink',

    // Amarillos y naranjas
    yellow: 'yellow',
    amber: 'amber',
    orange: 'orange',

    // Púrpuras
    purple: 'purple',
    violet: 'violet',

    // Neutrales
    gray: 'gray',
    slate: 'slate',
    zinc: 'zinc',
    stone: 'stone',
};

/**
 * Obtiene un color por su clave
 * @param {string} key - Clave del color a buscar
 * @returns {string|null} - Valor del color o null si no se encuentra
 */
export function getLevelColorByKey(key) {
    return LEVEL_COLORS[key] || null;
}

/**
 * Obtiene los estilos CSS para un tag según la clave de color y tema
 * @param {string} colorKey - Clave del color
 * @param {boolean} isDarkMode - Si está en modo oscuro
 * @returns {object} - Objeto con propiedades CSS
 */
export function getLevelTagStyle(colorKey, isDarkMode = false) {
    // Si no hay color definido, usar azul
    const key = findLevelColor(colorKey);
    
    // Configurar shades según el modo
    const textShade = isDarkMode ? '300' : '700';
    const bgShade = isDarkMode ? '500' : '100';
    
    // En modo oscuro aplicamos opacidad con color-mix
    if (isDarkMode) {
        return {
            color: `var(--p-${LEVEL_COLORS[key]}-${textShade})`,
            backgroundColor: `color-mix(in srgb, var(--p-${LEVEL_COLORS[key]}-${bgShade}), transparent 84%)`,
        };
    } else {
        // En modo claro usamos el color sólido
        return {
            color: `var(--p-${LEVEL_COLORS[key]}-${textShade})`,
            backgroundColor: `var(--p-${LEVEL_COLORS[key]}-${bgShade})`,
        };
    }
}

/**
 * Busca un color por clave o valor anterior
 * @param {string} colorIdentifier - Clave de color o valor antiguo
 * @returns {string} - Clave de color normalizada
 */
export function findLevelColor(colorIdentifier) {
    if (!colorIdentifier) return 'blue';
    
    // Si es una clave válida en nuestro objeto, devolverla directamente
    if (LEVEL_COLORS[colorIdentifier]) return colorIdentifier;
    
    // Migración desde colores antiguos con claves de tipo
    const colorMigration = {
        'primary': 'blue',
        'secondary': 'slate',
        'success': 'green',
        'info': 'cyan',
        'warning': 'amber',
        'danger': 'red'
    };
    
    if (colorMigration[colorIdentifier]) {
        return colorMigration[colorIdentifier];
    }
    
    // Si no se encuentra de ninguna forma, devolver azul como color por defecto
    console.warn(`Color no reconocido: "${colorIdentifier}", usando blue como fallback`);
    return 'blue';
}

/**
 * Obtiene los datos de color para usar con la API antigua
 * @param {string} colorKey - Clave del color
 * @param {boolean} isDarkMode - Si estamos en modo oscuro
 * @returns {object} - Datos compatibles con la API antigua
 */
export function getLevelColorForTheme(colorKey, isDarkMode = false) {
    // Esta función se mantiene por compatibilidad con código existente
    // pero ahora usa la nueva implementación internamente
    const key = findLevelColor(colorKey);
    const style = getLevelTagStyle(key, isDarkMode);

    return {
        background: style.backgroundColor,
        text: style.color
    };
}