import { ref, computed, watch } from 'vue'
import { defineStore } from 'pinia'

export const useUIStore = defineStore('ui', () => {
    // Estados básicos de UI
    const darkMode = ref(false);
    const firstPageLoading = ref(false);
    const pageTitle = ref('Finheal');
    const firstLoad = ref(true);
    let interval = null
    const pageLoading = ref(false);
    const pageLoadingProgress = ref(0);
    const pageLoadingColor = ref('var(--p-primary-color)');

    // Variable para controlar si ya se cargó la configuración inicial
    let isLoaded = false;

    const sidebarModel = ref([
        {
            label: 'Inicio',
            items: [{ label: 'Dashboard', icon: 'home', to: '/' }]
        },
        {
            label: 'Modulos',
            items: [
                { label: 'Gráficas', icon: 'bar_chart', to: '/charts' },
            ]
        },
        {
            label: 'Catálogos',
            items: [
                { label: 'Categorías', icon: 'category', to: '/categories' },
                { label: 'Niveles', icon: 'backlight_low', to: '/levels' },
                { label: 'Bancos', icon: 'account_balance', to: '/banks' }
            ]
        },
        {
            label: 'Personal',
            items: [
                { label: 'Cuentas', icon: 'account_balance_wallet', to: '/accounts' },
            ]
        },
        {
            label: 'Páginas',
            items: [
                {
                    label: 'Landing',
                    icon: 'language',
                    to: '/landing'
                },
                {
                    label: 'Error',
                    icon: 'cancel',
                    to: '/error'
                },
                {
                    label: 'Access Denied',
                    icon: 'lock',
                    to: '/access-denied'
                },
                {
                    label: 'Not Found',
                    icon: 'error',
                    to: 'notfound'
                },
                {
                    label: 'Empty',
                    icon: 'circle',
                    to: '/empty'
                }
            ]
        },
        {
            label: 'Extras',
            items: [
                {
                    label: 'Repositorio',
                    icon: 'pi pi-fw pi-github',
                    primeicon: true,
                    url: 'https://github.com/iDylaan/Finah',
                    target: '_blank'
                }
            ]
        }
    ]);

    // Estados del layout migrados desde layout.js
    const layoutConfig = ref({
        preset: 'Aura',
        primary: 'emerald',
        surface: null,
        darkTheme: false,
        menuMode: 'static'
    });

    const layoutState = ref({
        staticMenuDesktopInactive: false,
        overlayMenuActive: false,
        profileSidebarVisible: false,
        configSidebarVisible: false,
        staticMenuMobileActive: false,
        menuHoverActive: false,
        activeMenuItem: null
    });

    // Función para guardar toda la configuración UI
    const saveUIConfig = () => {
        const uiConfig = {
            darkMode: darkMode.value,
            layoutConfig: layoutConfig.value,
            layoutState: {
                staticMenuDesktopInactive: layoutState.value.staticMenuDesktopInactive,
                profileSidebarVisible: layoutState.value.profileSidebarVisible,
                configSidebarVisible: layoutState.value.configSidebarVisible,
                activeMenuItem: layoutState.value.activeMenuItem
            }
        };
        localStorage.setItem('finheal_ui', JSON.stringify(uiConfig));
    };

    // Watch para guardar automáticamente cambios en layoutConfig (solo después de cargar)
    watch(
        layoutConfig,
        () => {
            if (isLoaded) {
                saveUIConfig();
            }
        },
        { deep: true }
    );

    // Watch para guardar cambios en layoutState (solo algunos estados persistentes)
    watch(
        () => ({
            staticMenuDesktopInactive: layoutState.value.staticMenuDesktopInactive,
            profileSidebarVisible: layoutState.value.profileSidebarVisible,
            configSidebarVisible: layoutState.value.configSidebarVisible,
            activeMenuItem: layoutState.value.activeMenuItem
        }),
        () => {
            if (isLoaded) {
                saveUIConfig();
            }
        },
        { deep: true }
    );

    // Watch para darkMode
    watch(
        darkMode,
        () => {
            if (isLoaded) {
                layoutConfig.value.darkTheme = darkMode.value;
                document.documentElement.classList.toggle('app-dark', darkMode.value);
                saveUIConfig();
            }
        }
    );

    // Computed properties
    const barStyle = computed(() => ({
        width: `${pageLoadingProgress.value}%`,
        backgroundColor: pageLoadingColor.value
    }));

    const isSidebarActive = computed(() =>
        layoutState.value.overlayMenuActive || layoutState.value.staticMenuMobileActive
    );

    const isDarkTheme = computed(() => layoutConfig.value.darkTheme);

    const getPrimary = computed(() => layoutConfig.value.primary);

    const getSurface = computed(() => layoutConfig.value.surface);

    // Función para aplicar el tema completo usando PrimeVue
    const applyFullTheme = () => {
        // Intentar aplicar varias veces con diferentes delays para asegurar que funcione
        const tryApply = (delay = 500) => {
            setTimeout(() => {
                if (typeof window !== 'undefined') {
                    // Disparar evento personalizado para que AppConfigurator aplique el tema
                    window.dispatchEvent(new CustomEvent('applyStoredTheme', {
                        detail: {
                            primary: layoutConfig.value.primary,
                            surface: layoutConfig.value.surface,
                            preset: layoutConfig.value.preset,
                            darkTheme: layoutConfig.value.darkTheme
                        }
                    }));
                }
            }, delay);
        };

        // Intentar aplicar múltiples veces para asegurar que funcione
        tryApply(100);
        tryApply(500);
        tryApply(1000);
    };

    // FUNCTIONS originales
    const toggleDarkMode = () => {
        darkMode.value = !darkMode.value;
        // El watch se encargará del resto
    };

    const executeDarkModeToggle = () => {
        if (!document.startViewTransition) {
            toggleDarkMode();
            return;
        }
        document.startViewTransition(() => toggleDarkMode());
    };

    // Funciones del layout migradas
    const setActiveMenuItem = (item) => {
        layoutState.value.activeMenuItem = item.value || item;
        // El watch se encargará de guardar
    };

    const toggleMenu = () => {
        if (layoutConfig.value.menuMode === 'overlay') {
            layoutState.value.overlayMenuActive = !layoutState.value.overlayMenuActive;
        }

        if (window.innerWidth > 991) {
            layoutState.value.staticMenuDesktopInactive = !layoutState.value.staticMenuDesktopInactive;
        } else {
            layoutState.value.staticMenuMobileActive = !layoutState.value.staticMenuMobileActive;
        }
        // El watch se encargará de guardar los estados persistentes
    };

    // Nueva función para ocultar menú
    const hideMenu = () => {
        layoutState.value.overlayMenuActive = false;
        layoutState.value.staticMenuMobileActive = false;
        layoutState.value.menuHoverActive = false;
    };

    const toggleProfileSidebar = () => {
        layoutState.value.profileSidebarVisible = !layoutState.value.profileSidebarVisible;
        // El watch se encargará de guardar
    };

    const toggleConfigSidebar = () => {
        layoutState.value.configSidebarVisible = !layoutState.value.configSidebarVisible;
        // El watch se encargará de guardar
    };

    const setMenuMode = (mode) => {
        layoutConfig.value.menuMode = mode;
        // El watch se encargará de guardar
    };

    const setPrimaryColor = (color) => {
        layoutConfig.value.primary = color;
        // El watch se encargará de guardar
    };

    const setSurface = (surface) => {
        layoutConfig.value.surface = surface;
        // El watch se encargará de guardar
    };

    const setPreset = (preset) => {
        layoutConfig.value.preset = preset;
        // El watch se encargará de guardar
    };

    // Función para cargar la configuración UI
    const loadUISetup = () => {
        const savedConfig = localStorage.getItem('finheal_ui');

        if (savedConfig) {
            try {
                const config = JSON.parse(savedConfig);

                // Cargar configuración básica
                if (config.darkMode !== undefined) {
                    darkMode.value = config.darkMode;
                    layoutConfig.value.darkTheme = config.darkMode;
                }

                // Cargar configuración del layout
                if (config.layoutConfig) {
                    Object.assign(layoutConfig.value, config.layoutConfig);
                    darkMode.value = config.layoutConfig.darkTheme;
                }

                // Cargar estado del layout (solo estados persistentes)
                if (config.layoutState) {
                    Object.assign(layoutState.value, {
                        ...layoutState.value,
                        ...config.layoutState,
                        overlayMenuActive: false,
                        staticMenuMobileActive: false,
                        menuHoverActive: false
                    });
                }

                // Aplicar clases CSS según la configuración cargada
                document.documentElement.classList.toggle('app-dark', layoutConfig.value.darkTheme);

            } catch (error) {
                console.error('Error loading UI config:', error);
            }
        } else {
        }

        // Marcar como cargado para habilitar los watchers
        isLoaded = true;

        // Aplicar configuración de tema después de cargar
        applyFullTheme();

        // Guardar configuración actual (primera vez o después de cargar)
        if (!savedConfig) {
            saveUIConfig();
        }
    };

    // Funciones originales restantes
    const setFirstPageLoading = (ms) => {
        firstPageLoading.value = true;
        setTimeout(() => {
            firstPageLoading.value = false;
        }, ms);
    };

    const getFirstLoad = () => firstLoad.value;
    const setFirstLoaded = () => firstLoad.value = false;

    const setPageTitle = (title) => {
        const fullTitle = title.length > 0 ? `Finheal | ${title}` : 'Finheal';
        document.title = fullTitle;
        pageTitle.value = title;
    };

    const startPageLoading = () => {
        pageLoading.value = true;
        pageLoadingColor.value = 'var(--p-primary-color)';
        pageLoadingProgress.value = 0;

        clearInterval(interval);
        interval = setInterval(() => {
            if (pageLoadingProgress.value < 75) {
                pageLoadingProgress.value += 1;
            } else {
                clearInterval(interval);
            }
        }, 30);
    };

    const finishPageLoading = () => {
        clearInterval(interval);
        pageLoadingProgress.value = 100;
        setTimeout(() => {
            pageLoading.value = false;
            pageLoadingProgress.value = 0;
        }, 300);
    };

    const errorPageLoading = () => {
        clearInterval(interval);
        pageLoadingColor.value = 'red';
        pageLoadingProgress.value = 100;
        setTimeout(() => {
            pageLoading.value = false;
            pageLoadingProgress.value = 0;
            pageLoadingColor.value = 'var(--p-primary-color)';
        }, 500);
    };

    const deactivateFirstLoading = () => firstLoad.value = false;
    const activateFirstLoading = () => firstLoad.value = true;

    return {
        // Estados básicos
        pageTitle,
        darkMode,
        firstPageLoading,
        pageLoading,
        barStyle,
        firstLoad,

        // Estados del layout
        layoutConfig,
        layoutState,

        // Computed del layout
        isSidebarActive,
        isDarkTheme,
        getPrimary,
        getSurface,

        // Sidebar
        sidebarModel,

        // Funciones básicas
        setFirstPageLoading,
        toggleDarkMode,
        executeDarkModeToggle,
        loadUISetup,
        saveUIConfig,
        setPageTitle,
        getFirstLoad,
        setFirstLoaded,
        startPageLoading,
        finishPageLoading,
        errorPageLoading,
        deactivateFirstLoading,
        activateFirstLoading,
        applyFullTheme,

        // Funciones del layout
        setActiveMenuItem,
        toggleMenu,
        hideMenu,
        toggleProfileSidebar,
        toggleConfigSidebar,
        setMenuMode,
        setPrimaryColor,
        setSurface,
        setPreset
    };
});