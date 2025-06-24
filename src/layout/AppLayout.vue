<script setup>
import { useUIStore } from '@/stores/ui';
import { computed, ref, watch } from 'vue';
import AppFooter from './AppFooter.vue';
import AppSidebar from './AppSidebar.vue';
import AppTopbar from './AppTopbar.vue';

const uiStore = useUIStore();

const outsideClickListener = ref(null);

// Watch para el overlay activo
watch(() => uiStore.layoutState.overlayMenuActive, (newVal) => {
    if (newVal) {
        bindOutsideClickListener();
    } else {
        unbindOutsideClickListener();
    }
});

// Watch para el menú móvil activo
watch(() => uiStore.layoutState.staticMenuMobileActive, (newVal) => {
    if (newVal) {
        bindOutsideClickListener();
    } else {
        unbindOutsideClickListener();
    }
});

const containerClass = computed(() => {
    return {
        'layout-overlay': uiStore.layoutConfig.menuMode === 'overlay',
        'layout-static': uiStore.layoutConfig.menuMode === 'static',
        'layout-static-inactive': uiStore.layoutState.staticMenuDesktopInactive && uiStore.layoutConfig.menuMode === 'static',
        'layout-overlay-active': uiStore.layoutState.overlayMenuActive,
        'layout-mobile-active': uiStore.layoutState.staticMenuMobileActive
    };
});

function bindOutsideClickListener() {
    if (!outsideClickListener.value) {
        outsideClickListener.value = (event) => {
            if (isOutsideClicked(event)) {
                uiStore.hideMenu();
            }
        };
        document.addEventListener('click', outsideClickListener.value);
    }
}

function unbindOutsideClickListener() {
    if (outsideClickListener.value) {
        document.removeEventListener('click', outsideClickListener.value);
        outsideClickListener.value = null;
    }
}

function isOutsideClicked(event) {
    const sidebarEl = document.querySelector('.layout-sidebar');
    const topbarEl = document.querySelector('.layout-menu-button');

    return !(sidebarEl?.isSameNode(event.target) || sidebarEl?.contains(event.target) || topbarEl?.isSameNode(event.target) || topbarEl?.contains(event.target));
}

function onMaskClick() {
    uiStore.hideMenu();
}
</script>

<template>
    <div class="layout-wrapper" :class="containerClass">
        <app-topbar></app-topbar>
        <app-sidebar></app-sidebar>
        <div class="layout-main-container">
            <div class="layout-main">
                <router-view></router-view>
            </div>
            <app-footer></app-footer>
        </div>
        <div 
            v-if="uiStore.layoutState.overlayMenuActive || uiStore.layoutState.staticMenuMobileActive" 
            class="layout-mask animate-fadein"
            @click="onMaskClick"
        ></div>
    </div>
</template>
