<script setup>
import { $t, updatePreset, updateSurfacePalette } from '@primeuix/themes';
import Aura from '@primeuix/themes/aura';
import { ref, onMounted, watch, nextTick } from 'vue';

// STORES
import { useUIStore } from '@/stores/ui.js';
const UI = useUIStore();

// Tema fijo en Aura
const preset = ref('Aura');
const presets = { Aura };

const menuMode = ref(UI.layoutConfig.menuMode);
const menuModeOptions = ref([
    { label: 'Estático', value: 'static' },
    { label: 'Sobrepuesto', value: 'overlay' }
]);

const primaryColors = ref([
    // ===== ESPECIAL =====
    { name: 'noir', palette: {} },
    
    // ===== ROJOS (Red Spectrum) =====
    { name: 'red', palette: { 50: '#fef2f2', 100: '#fee2e2', 200: '#fecaca', 300: '#fca5a5', 400: '#f87171', 500: '#ef4444', 600: '#dc2626', 700: '#b91c1c', 800: '#991b1b', 900: '#7f1d1d', 950: '#450a0a' } },
    { name: 'ruby', palette: { 50: '#fef2f2', 100: '#fee2e2', 200: '#fecaca', 300: '#fca5a5', 400: '#f87171', 500: '#ef4444', 600: '#dc2626', 700: '#b91c1c', 800: '#991b1b', 900: '#7f1d1d', 950: '#450a0a' } },
    { name: 'crimson', palette: { 50: '#fef2f4', 100: '#fde6e9', 200: '#fcd0d7', 300: '#faa8b6', 400: '#f6728f', 500: '#ed4f6d', 600: '#d6295f', 700: '#b31d4e', 800: '#961b47', 900: '#801a42', 950: '#470920' } },
    
    // ===== ROSAS (Pink Spectrum) =====
    { name: 'rose', palette: { 50: '#fff1f2', 100: '#ffe4e6', 200: '#fecdd3', 300: '#fda4af', 400: '#fb7185', 500: '#f43f5e', 600: '#e11d48', 700: '#be123c', 800: '#9f1239', 900: '#881337', 950: '#4c0519' } },
    { name: 'pink', palette: { 50: '#fdf2f8', 100: '#fce7f3', 200: '#fbcfe8', 300: '#f9a8d4', 400: '#f472b6', 500: '#ec4899', 600: '#db2777', 700: '#be185d', 800: '#9d174d', 900: '#831843', 950: '#500724' } },
    
    // ===== NARANJAS (Orange Spectrum) =====
    { name: 'orange', palette: { 50: '#fff7ed', 100: '#ffedd5', 200: '#fed7aa', 300: '#fdba74', 400: '#fb923c', 500: '#f97316', 600: '#ea580c', 700: '#c2410c', 800: '#9a3412', 900: '#7c2d12', 950: '#431407' } },
    { name: 'coral', palette: { 50: '#fff5f3', 100: '#ffe8e3', 200: '#ffd4cc', 300: '#ffb5a8', 400: '#ff8a75', 500: '#ff6347', 600: '#f04a2e', 700: '#d63617', 800: '#b02a14', 900: '#8f2516', 950: '#4e1007' } },
    { name: 'peach', palette: { 50: '#fff7ed', 100: '#ffedd5', 200: '#fed7aa', 300: '#fdba74', 400: '#fb923c', 500: '#f97316', 600: '#ea580c', 700: '#c2410c', 800: '#9a3412', 900: '#7c2d12', 950: '#431407' } },
    { name: 'sunset', palette: { 50: '#fff7ed', 100: '#ffedd5', 200: '#fed7aa', 300: '#fdba74', 400: '#fb923c', 500: '#f97316', 600: '#ea580c', 700: '#c2410c', 800: '#9a3412', 900: '#7c2d12', 950: '#431407' } },
    
    // ===== AMARILLOS (Yellow Spectrum) =====
    { name: 'amber', palette: { 50: '#fffbeb', 100: '#fef3c7', 200: '#fde68a', 300: '#fcd34d', 400: '#fbbf24', 500: '#f59e0b', 600: '#d97706', 700: '#b45309', 800: '#92400e', 900: '#78350f', 950: '#451a03' } },
    { name: 'yellow', palette: { 50: '#fefce8', 100: '#fef9c3', 200: '#fef08a', 300: '#fde047', 400: '#facc15', 500: '#eab308', 600: '#ca8a04', 700: '#a16207', 800: '#854d0e', 900: '#713f12', 950: '#422006' } },
    { name: 'gold', palette: { 50: '#fffbeb', 100: '#fef3c7', 200: '#fde68a', 300: '#fcd34d', 400: '#fbbf24', 500: '#f59e0b', 600: '#d97706', 700: '#b45309', 800: '#92400e', 900: '#78350f', 950: '#451a03' } },
    
    // ===== VERDES AMARILLENTOS (Yellow-Green Spectrum) =====
    { name: 'lime', palette: { 50: '#f7fee7', 100: '#ecfccb', 200: '#d9f99d', 300: '#bef264', 400: '#a3e635', 500: '#84cc16', 600: '#65a30d', 700: '#4d7c0f', 800: '#3f6212', 900: '#365314', 950: '#1a2e05' } },
    
    // ===== VERDES (Green Spectrum) =====
    { name: 'green', palette: { 50: '#f0fdf4', 100: '#dcfce7', 200: '#bbf7d0', 300: '#86efac', 400: '#4ade80', 500: '#22c55e', 600: '#16a34a', 700: '#15803d', 800: '#166534', 900: '#14532d', 950: '#052e16' } },
    { name: 'emerald', palette: { 50: '#ecfdf5', 100: '#d1fae5', 200: '#a7f3d0', 300: '#6ee7b7', 400: '#34d399', 500: '#10b981', 600: '#059669', 700: '#047857', 800: '#065f46', 900: '#064e3b', 950: '#022c22' } },
    { name: 'forest', palette: { 50: '#f0fdf4', 100: '#dcfce7', 200: '#bbf7d0', 300: '#86efac', 400: '#4ade80', 500: '#22c55e', 600: '#16a34a', 700: '#15803d', 800: '#166534', 900: '#14532d', 950: '#052e16' } },
    { name: 'mint', palette: { 50: '#f0fdf9', 100: '#ccfbef', 200: '#9af6e1', 300: '#5feace', 400: '#2dd4b8', 500: '#14b89f', 600: '#0d9488', 700: '#0f766e', 800: '#115e59', 900: '#134e4a', 950: '#042f2e' } },
    
    // ===== VERDES AZULADOS (Teal Spectrum) =====
    { name: 'teal', palette: { 50: '#f0fdfa', 100: '#ccfbf1', 200: '#99f6e4', 300: '#5eead4', 400: '#2dd4bf', 500: '#14b8a6', 600: '#0d9488', 700: '#0f766e', 800: '#115e59', 900: '#134e4a', 950: '#042f2e' } },
    { name: 'turquoise', palette: { 50: '#f0fdfa', 100: '#ccfbf1', 200: '#99f6e4', 300: '#5eead4', 400: '#2dd4bf', 500: '#14b8a6', 600: '#0d9488', 700: '#0f766e', 800: '#115e59', 900: '#134e4a', 950: '#042f2e' } },
    
    // ===== CIANES (Cyan Spectrum) =====
    { name: 'cyan', palette: { 50: '#ecfeff', 100: '#cffafe', 200: '#a5f3fc', 300: '#67e8f9', 400: '#22d3ee', 500: '#06b6d4', 600: '#0891b2', 700: '#0e7490', 800: '#155e75', 900: '#164e63', 950: '#083344' } },
    { name: 'aqua', palette: { 50: '#ecfeff', 100: '#cffafe', 200: '#a5f3fc', 300: '#67e8f9', 400: '#22d3ee', 500: '#06b6d4', 600: '#0891b2', 700: '#0e7490', 800: '#155e75', 900: '#164e63', 950: '#083344' } },
    
    // ===== AZULES CLAROS (Sky Blue Spectrum) =====
    { name: 'sky', palette: { 50: '#f0f9ff', 100: '#e0f2fe', 200: '#bae6fd', 300: '#7dd3fc', 400: '#38bdf8', 500: '#0ea5e9', 600: '#0284c7', 700: '#0369a1', 800: '#075985', 900: '#0c4a6e', 950: '#082f49' } },
    
    // ===== AZULES (Blue Spectrum) =====
    { name: 'blue', palette: { 50: '#eff6ff', 100: '#dbeafe', 200: '#bfdbfe', 300: '#93c5fd', 400: '#60a5fa', 500: '#3b82f6', 600: '#2563eb', 700: '#1d4ed8', 800: '#1e40af', 900: '#1e3a8a', 950: '#172554' } },
    { name: 'sapphire', palette: { 50: '#eff6ff', 100: '#dbeafe', 200: '#bfdbfe', 300: '#93c5fd', 400: '#60a5fa', 500: '#3b82f6', 600: '#2563eb', 700: '#1d4ed8', 800: '#1e40af', 900: '#1e3a8a', 950: '#172554' } },
    { name: 'cobalt', palette: { 50: '#eff6ff', 100: '#dbeafe', 200: '#bfdbfe', 300: '#93c5fd', 400: '#60a5fa', 500: '#3b82f6', 600: '#2563eb', 700: '#1d4ed8', 800: '#1e40af', 900: '#1e3a8a', 950: '#172554' } },
    
    // ===== ÍNDIGOS (Indigo Spectrum) =====
    { name: 'indigo', palette: { 50: '#eef2ff', 100: '#e0e7ff', 200: '#c7d2fe', 300: '#a5b4fc', 400: '#818cf8', 500: '#6366f1', 600: '#4f46e5', 700: '#4338ca', 800: '#3730a3', 900: '#312e81', 950: '#1e1b4b' } },
    
    // ===== VIOLETAS (Violet Spectrum) =====
    { name: 'violet', palette: { 50: '#f5f3ff', 100: '#ede9fe', 200: '#ddd6fe', 300: '#c4b5fd', 400: '#a78bfa', 500: '#8b5cf6', 600: '#7c3aed', 700: '#6d28d9', 800: '#5b21b6', 900: '#4c1d95', 950: '#2e1065' } },
    { name: 'lavender', palette: { 50: '#faf5ff', 100: '#f3e8ff', 200: '#e9d5ff', 300: '#d8b4fe', 400: '#c084fc', 500: '#a855f7', 600: '#9333ea', 700: '#7e22ce', 800: '#6b21a8', 900: '#581c87', 950: '#3b0764' } },
    
    // ===== PÚRPURAS (Purple Spectrum) =====
    { name: 'purple', palette: { 50: '#faf5ff', 100: '#f3e8ff', 200: '#e9d5ff', 300: '#d8b4fe', 400: '#c084fc', 500: '#a855f7', 600: '#9333ea', 700: '#7e22ce', 800: '#6b21a8', 900: '#581c87', 950: '#3b0764' } },
    { name: 'amethyst', palette: { 50: '#faf5ff', 100: '#f3e8ff', 200: '#e9d5ff', 300: '#d8b4fe', 400: '#c084fc', 500: '#a855f7', 600: '#9333ea', 700: '#7e22ce', 800: '#6b21a8', 900: '#581c87', 950: '#3b0764' } },
    
    // ===== FUCSIAS Y MAGENTAS (Fuchsia/Magenta Spectrum) =====
    { name: 'fuchsia', palette: { 50: '#fdf4ff', 100: '#fae8ff', 200: '#f5d0fe', 300: '#f0abfc', 400: '#e879f9', 500: '#d946ef', 600: '#c026d3', 700: '#a21caf', 800: '#86198f', 900: '#701a75', 950: '#4a044e' } }
]);

const surfaces = ref([
    // ===== NEUTRALES PUROS (Versátiles universales) =====
    {
        name: 'neutral',
        palette: { 0: '#ffffff', 50: '#fafafa', 100: '#f5f5f5', 200: '#e5e5e5', 300: '#d4d4d4', 400: '#a3a3a3', 500: '#737373', 600: '#525252', 700: '#404040', 800: '#262626', 900: '#171717', 950: '#0a0a0a' }
    },
    {
        name: 'gray',
        palette: { 0: '#ffffff', 50: '#f9fafb', 100: '#f3f4f6', 200: '#e5e7eb', 300: '#d1d5db', 400: '#9ca3af', 500: '#6b7280', 600: '#4b5563', 700: '#374151', 800: '#1f2937', 900: '#111827', 950: '#030712' }
    },
    {
        name: 'zinc',
        palette: { 0: '#ffffff', 50: '#fafafa', 100: '#f4f4f5', 200: '#e4e4e7', 300: '#d4d4d8', 400: '#a1a1aa', 500: '#71717a', 600: '#52525b', 700: '#3f3f46', 800: '#27272a', 900: '#18181b', 950: '#09090b' }
    },
    {
        name: 'noir',
        palette: { 0: '#ffffff', 50: '#f9f9f9', 100: '#f0f0f0', 200: '#e0e0e0', 300: '#cccccc', 400: '#adadad', 500: '#8a8a8a', 600: '#6b6b6b', 700: '#4f4f4f', 800: '#333333', 900: '#1a1a1a', 950: '#0d0d0d' }
    },
    {
        name: 'graphite',
        palette: { 0: '#ffffff', 50: '#f8f8f8', 100: '#efefef', 200: '#dfdfdf', 300: '#cacaca', 400: '#ababab', 500: '#888888', 600: '#696969', 700: '#4d4d4d', 800: '#313131', 900: '#1c1c1c', 950: '#0e0e0e' }
    },
    {
        name: 'charcoal',
        palette: { 0: '#ffffff', 50: '#f7f7f7', 100: '#ededed', 200: '#dedede', 300: '#c8c8c8', 400: '#a8a8a8', 500: '#868686', 600: '#676767', 700: '#4b4b4b', 800: '#2f2f2f', 900: '#1a1a1a', 950: '#0c0c0c' }
    },
    
    // ===== TONOS FRÍOS (Ideales para blues, cyans, teals) =====
    {
        name: 'slate',
        palette: { 0: '#ffffff', 50: '#f8fafc', 100: '#f1f5f9', 200: '#e2e8f0', 300: '#cbd5e1', 400: '#94a3b8', 500: '#64748b', 600: '#475569', 700: '#334155', 800: '#1e293b', 900: '#0f172a', 950: '#020617' }
    },
    {
        name: 'cool',
        palette: { 0: '#ffffff', 50: '#f8f9fa', 100: '#f1f3f5', 200: '#e1e6ea', 300: '#cfd6dd', 400: '#b0bac4', 500: '#8b97a3', 600: '#6d7884', 700: '#535c67', 800: '#3c434c', 900: '#282d33', 950: '#15181b' }
    },
    {
        name: 'steel',
        palette: { 0: '#ffffff', 50: '#f7f8f9', 100: '#eef0f2', 200: '#dce0e4', 300: '#c7ced5', 400: '#a6b1bc', 500: '#828f9c', 600: '#66717d', 700: '#4e5760', 800: '#383f46', 900: '#262b30', 950: '#14171a' }
    },
    {
        name: 'ocean',
        palette: { 0: '#ffffff', 50: '#f7f9fa', 100: '#eff3f5', 200: '#dce5e9', 300: '#c6d4db', 400: '#a3b5c0', 500: '#7d92a0', 600: '#5f7380', 700: '#475763', 800: '#323e48', 900: '#222a31', 950: '#12161a' }
    },
    {
        name: 'arctic',
        palette: { 0: '#ffffff', 50: '#f8f9fa', 100: '#f0f2f4', 200: '#dfe4e8', 300: '#cbd3d9', 400: '#acb7c0', 500: '#8a98a3', 600: '#6c7a85', 700: '#525e68', 800: '#3a444c', 900: '#272d33', 950: '#14171a' }
    },
    {
        name: 'midnight',
        palette: { 0: '#ffffff', 50: '#f6f7f8', 100: '#eceef0', 200: '#d8dce0', 300: '#c0c6cd', 400: '#9fa7b2', 500: '#7a8491', 600: '#5e6874', 700: '#474f59', 800: '#323840', 900: '#21252b', 950: '#111316' }
    },
    
    // ===== TONOS EQUILIBRADOS (Balance perfecto entre cálido y frío) =====
    {
        name: 'stone',
        palette: { 0: '#ffffff', 50: '#fafaf9', 100: '#f5f5f4', 200: '#e7e5e4', 300: '#d6d3d1', 400: '#a8a29e', 500: '#78716c', 600: '#57534e', 700: '#44403c', 800: '#292524', 900: '#1c1917', 950: '#0c0a09' }
    },
    {
        name: 'pebble',
        palette: { 0: '#ffffff', 50: '#f9f9f8', 100: '#f3f2f1', 200: '#e6e4e2', 300: '#d5d2cf', 400: '#b8b4b0', 500: '#96918c', 600: '#77736f', 700: '#5c5955', 800: '#43403d', 900: '#2d2b29', 950: '#171615' }
    },
    
    // ===== TONOS CÁLIDOS (Perfectos para oranges, ambers, reds) =====
    {
        name: 'warm',
        palette: { 0: '#ffffff', 50: '#fafaf9', 100: '#f5f4f2', 200: '#e9e7e3', 300: '#dbd8d2', 400: '#c4bfb6', 500: '#a39d92', 600: '#837d73', 700: '#65615a', 800: '#4a4743', 900: '#32302d', 950: '#1a1918' }
    },
    {
        name: 'sand',
        palette: { 0: '#ffffff', 50: '#faf9f7', 100: '#f5f2ed', 200: '#ebe6db', 300: '#ddd6c8', 400: '#c8bfae', 500: '#a89f8d', 600: '#8a8270', 700: '#6d665a', 800: '#4f4942', 900: '#38342e', 950: '#1c1a17' }
    },
    {
        name: 'beige',
        palette: { 0: '#ffffff', 50: '#faf9f6', 100: '#f4f2eb', 200: '#e8e4d8', 300: '#dad4c3', 400: '#c5bca5', 500: '#a89c81', 600: '#8a7e66', 700: '#6d634f', 800: '#504839', 900: '#383227', 950: '#1d1b16' }
    },
    {
        name: 'caramel',
        palette: { 0: '#ffffff', 50: '#faf8f5', 100: '#f4f1ea', 200: '#e8e2d5', 300: '#d9d0be', 400: '#c4b69d', 500: '#a99577', 600: '#8b775b', 700: '#6c5d46', 800: '#4e4433', 900: '#352f23', 950: '#1b1812' }
    },
    
    // ===== TONOS NATURALES VERDES (Para greens, emeralds, limes) =====
    {
        name: 'sage',
        palette: { 0: '#ffffff', 50: '#f8f9f8', 100: '#f1f3f1', 200: '#e2e6e3', 300: '#d1d7d2', 400: '#b5bfb7', 500: '#939f95', 600: '#747f76', 700: '#59625b', 800: '#404743', 900: '#2c312e', 950: '#161918' }
    },
    {
        name: 'moss',
        palette: { 0: '#ffffff', 50: '#f8f9f7', 100: '#f0f2ee', 200: '#e1e5dd', 300: '#cfd5c9', 400: '#b5bead', 500: '#94a08a', 600: '#75816d', 700: '#5a6554', 800: '#42493e', 900: '#2d322b', 950: '#171a15' }
    },
    {
        name: 'olive',
        palette: { 0: '#ffffff', 50: '#f8f9f6', 100: '#f0f2ec', 200: '#e1e5d9', 300: '#cfd4c3', 400: '#b4bca3', 500: '#949d7f', 600: '#767e62', 700: '#5c624b', 800: '#434837', 900: '#2e3226', 950: '#171a14' }
    },
    
    // ===== TONOS VIBRANTES (Para purples, fuchsias, magentas) =====
    {
        name: 'lavender',
        palette: { 0: '#ffffff', 50: '#faf9fb', 100: '#f4f2f6', 200: '#e8e4ed', 300: '#dad3e2', 400: '#c4b9d3', 500: '#a595bc', 600: '#86759d', 700: '#685a7a', 800: '#4c4358', 900: '#342e3c', 950: '#1a171e' }
    },
    {
        name: 'plum',
        palette: { 0: '#ffffff', 50: '#faf9fa', 100: '#f4f2f5', 200: '#e9e5eb', 300: '#dbd5e0', 400: '#c5bccf', 500: '#a599b5', 600: '#857a96', 700: '#675e76', 800: '#4b4556', 900: '#33303b', 950: '#1a181d' }
    },
    {
        name: 'mauve',
        palette: { 0: '#ffffff', 50: '#faf9fb', 100: '#f4f1f5', 200: '#e9e3ed', 300: '#dbd2e1', 400: '#c4b7d0', 500: '#a493b3', 600: '#847493', 700: '#665974', 800: '#4b4256', 900: '#342e3b', 950: '#1a171d' }
    }
]);

// Variable para controlar si el componente está listo
let isComponentReady = false;

// Watcher para sincronizar menu mode con la store
watch(() => UI.layoutConfig.menuMode, (newMenuMode) => {
    menuMode.value = newMenuMode;
});

function getPresetExt() {
    const color = primaryColors.value.find((c) => c.name === UI.layoutConfig.primary);

    if (color && color.name === 'noir') {
        return {
            semantic: {
                primary: {
                    50: '{surface.50}',
                    100: '{surface.100}',
                    200: '{surface.200}',
                    300: '{surface.300}',
                    400: '{surface.400}',
                    500: '{surface.500}',
                    600: '{surface.600}',
                    700: '{surface.700}',
                    800: '{surface.800}',
                    900: '{surface.900}',
                    950: '{surface.950}'
                },
                colorScheme: {
                    light: {
                        primary: {
                            color: '{primary.950}',
                            contrastColor: '#ffffff',
                            hoverColor: '{primary.800}',
                            activeColor: '{primary.700}'
                        },
                        highlight: {
                            background: '{primary.950}',
                            focusBackground: '{primary.700}',
                            color: '#ffffff',
                            focusColor: '#ffffff'
                        }
                    },
                    dark: {
                        primary: {
                            color: '{primary.50}',
                            contrastColor: '{primary.950}',
                            hoverColor: '{primary.200}',
                            activeColor: '{primary.300}'
                        },
                        highlight: {
                            background: '{primary.50}',
                            focusBackground: '{primary.300}',
                            color: '{primary.950}',
                            focusColor: '{primary.950}'
                        }
                    }
                }
            }
        };
    } else if (color && color.palette) {
        return {
            semantic: {
                primary: color.palette,
                colorScheme: {
                    light: {
                        primary: {
                            color: '{primary.500}',
                            contrastColor: '#ffffff',
                            hoverColor: '{primary.600}',
                            activeColor: '{primary.700}'
                        },
                        highlight: {
                            background: '{primary.50}',
                            focusBackground: '{primary.100}',
                            color: '{primary.700}',
                            focusColor: '{primary.800}'
                        }
                    },
                    dark: {
                        primary: {
                            color: '{primary.400}',
                            contrastColor: '{surface.900}',
                            hoverColor: '{primary.300}',
                            activeColor: '{primary.200}'
                        },
                        highlight: {
                            background: 'color-mix(in srgb, {primary.400}, transparent 84%)',
                            focusBackground: 'color-mix(in srgb, {primary.400}, transparent 76%)',
                            color: 'rgba(255,255,255,.87)',
                            focusColor: 'rgba(255,255,255,.87)'
                        }
                    }
                }
            }
        };
    }
    return {};
}

function updateColors(type, color) {
    console.log(`🎨 Actualizando ${type}:`, color.name);
    
    // Guardar en la store
    if (type === 'primary') {
        UI.setPrimaryColor(color.name);
    } else if (type === 'surface') {
        UI.setSurface(color.name);
    }

    // Aplicar el cambio visual inmediatamente
    applyTheme(type, color);
    
    console.log('✅ Color aplicado y guardado');
}

function applyTheme(type, color) {
    // Aplicar el tema completo con la nueva configuración
    const presetValue = Aura;
    
    if (type === 'primary') {
        // Actualizar el preset con el nuevo color primario
        updatePreset(getPresetExt());
        
        // Obtener superficie actual
        const currentSurface = surfaces.value.find(s => s.name === UI.layoutConfig.surface);
        const surfacePalette = currentSurface?.palette || null;
        
        // Aplicar todo el tema de nuevo
        $t().preset(presetValue).preset(getPresetExt()).surfacePalette(surfacePalette).use({ useDefaultOptions: true });
        
    } else if (type === 'surface') {
        // Actualizar la paleta de superficie
        updateSurfacePalette(color.palette);
        
        // Aplicar todo el tema de nuevo
        $t().preset(presetValue).preset(getPresetExt()).surfacePalette(color.palette).use({ useDefaultOptions: true });
    }
}

function onMenuModeChange() {
    UI.setMenuMode(menuMode.value);
}

// Función para aplicar tema desde la store (al cargar la página)
function applyStoredTheme(config) {
    if (!isComponentReady) {
        setTimeout(() => applyStoredTheme(config), 200);
        return;
    }

    try {
        console.log('🎨 Aplicando tema guardado:', config);
        
        // Tema siempre Aura
        const presetValue = Aura;
        
        // Obtener color primario guardado
        const primaryColor = primaryColors.value.find(c => c.name === config.primary);
        let surfacePalette = null;
        
        // Obtener superficie guardada o usar por defecto según modo oscuro
        if (config.surface) {
            const surface = surfaces.value.find(s => s.name === config.surface);
            if (surface) {
                surfacePalette = surface.palette;
            }
        } else {
            // Si no hay surface guardado, usar el predeterminado según tema
            const defaultSurface = config.darkTheme ? 'zinc' : 'slate';
            const surface = surfaces.value.find(s => s.name === defaultSurface);
            if (surface) {
                surfacePalette = surface.palette;
            }
        }
        
        // Aplicar color primario usando el preset extension
        if (primaryColor) {
            updatePreset(getPresetExt());
        }
        
        // Aplicar superficie
        if (surfacePalette) {
            updateSurfacePalette(surfacePalette);
        }
        
        // Aplicar todo junto usando $t() con la configuración completa
        const themeConfig = $t()
            .preset(presetValue)
            .preset(getPresetExt())
            .surfacePalette(surfacePalette)
            .use({ useDefaultOptions: true });
        
        console.log('✅ Tema aplicado correctamente');
        
    } catch (error) {
        console.error('❌ Error aplicando tema guardado:', error);
    }
}

onMounted(async () => {
    // Esperar a que el componente esté completamente montado
    await nextTick();
    isComponentReady = true;
    
    console.log('⚙️ AppConfigurator montado, aplicando tema inicial');
    
    // Escuchar el evento de aplicar tema guardado
    window.addEventListener('applyStoredTheme', (event) => {
        console.log('📢 Evento applyStoredTheme recibido:', event.detail);
        applyStoredTheme(event.detail);
    });
    
    // Aplicar el tema actual de la store inmediatamente
    const currentTheme = {
        primary: UI.layoutConfig.primary,
        surface: UI.layoutConfig.surface,
        darkTheme: UI.layoutConfig.darkTheme
    };
    
    console.log('🎨 Aplicando tema inicial desde store:', currentTheme);
    applyStoredTheme(currentTheme);
});
</script>

<template>
    <div
        class="config-panel hidden absolute top-[3.25rem] right-0 w-64 p-4 bg-surface-0 dark:bg-surface-900 border border-surface rounded-border origin-top shadow-[0px_3px_5px_rgba(0,0,0,0.02),0px_0px_2px_rgba(0,0,0,0.05),0px_1px_4px_rgba(0,0,0,0.08)]"
    >
        <div class="flex flex-col gap-4">
            <div>
                <span class="text-sm text-muted-color font-semibold">Primario</span>
                <div class="pt-2 flex gap-2 flex-wrap justify-between">
                    <button
                        v-for="primaryColor of primaryColors"
                        :key="primaryColor.name"
                        type="button"
                        :title="primaryColor.name"
                        @click="updateColors('primary', primaryColor)"
                        :class="['border-none w-5 h-5 rounded-full p-0 cursor-pointer outline-none outline-offset-1', { 'outline-primary': UI.layoutConfig.primary === primaryColor.name }]"
                        :style="{ backgroundColor: `${primaryColor.name === 'noir' ? 'var(--text-color)' : primaryColor.palette['500']}` }"
                    ></button>
                </div>
            </div>
            <div>
                <span class="text-sm text-muted-color font-semibold">Superficie</span>
                <div class="pt-2 flex gap-2 flex-wrap justify-between">
                    <button
                        v-for="surface of surfaces"
                        :key="surface.name"
                        type="button"
                        :title="surface.name"
                        @click="updateColors('surface', surface)"
                        :class="[
                            'border-none w-5 h-5 rounded-full p-0 cursor-pointer outline-none outline-offset-1',
                            { 'outline-primary': UI.layoutConfig.surface ? UI.layoutConfig.surface === surface.name : UI.isDarkTheme ? surface.name === 'zinc' : surface.name === 'slate' }
                        ]"
                        :style="{ backgroundColor: `${surface.palette['500']}` }"
                    ></button>
                </div>
            </div>
            <div class="flex flex-col gap-2">
                <span class="text-sm text-muted-color font-semibold">Modo del menú</span>
                <SelectButton v-model="menuMode" @change="onMenuModeChange" :options="menuModeOptions" :allowEmpty="false" optionLabel="label" optionValue="value" />
            </div>
        </div>
    </div>
</template>
