import { ref, computed } from 'vue'
import { defineStore } from 'pinia'

export const useUIStore = defineStore('ui', () => {
    const darkMode = ref(false);
    const firstPageLoading = ref(false);
    const pageTitle = ref('Finheal');
    const firstLoad = ref(true);
    let interval = null
    const pageLoading = ref(false);
    const pageLoadingProgress = ref(0);
    const pageLoadingColor = ref('var(--p-primary-color)');
    const barStyle = computed(() => ({
        width: `${pageLoadingProgress.value}%`,
        backgroundColor: pageLoadingColor.value
    }));

    // FUNCTIONS
    const toggleDarkMode = () => {
        darkMode.value = !darkMode.value;
        document.documentElement.classList.toggle('dark');
        localStorage.setItem('finheal_dark_mode', JSON.stringify(darkMode.value));
    }

    const loadUISetup = () => {
        if (localStorage.getItem('finheal_dark_mode')) {
            darkMode.value = JSON.parse(localStorage.getItem('finheal_dark_mode'));
            document.documentElement.classList.toggle('dark', darkMode.value);
        }
    }

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
    }

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
        }, 30)
    }
    const finishPageLoading = () => {
        clearInterval(interval);
        pageLoadingProgress.value = 100;
        setTimeout(() => {
            pageLoading.value = false;
            pageLoadingProgress.value = 0;
        }, 300);
    }
    const errorPageLoading = () => {
        clearInterval(interval);
        pageLoadingColor.value = 'red';
        pageLoadingProgress.value = 100;
        setTimeout(() => {
            pageLoading.value = false;
            pageLoadingProgress.value = 0;
            pageLoadingColor.value = 'var(--p-primary-color)'
        }, 500);
    }

    const deactivateFirstLoading = () => firstLoad.value = false;
    const activateFirstLoading = () => firstLoad.value = true;

    return {
        pageTitle,
        darkMode,
        firstPageLoading,
        pageLoading,
        barStyle,
        setFirstPageLoading,
        toggleDarkMode,
        loadUISetup,
        setPageTitle,
        getFirstLoad,
        setFirstLoaded,
        startPageLoading,
        finishPageLoading,
        errorPageLoading,
        deactivateFirstLoading,
        activateFirstLoading,
    }
})
