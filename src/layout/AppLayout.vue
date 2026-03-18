<script setup>
import { useUIStore } from '@/stores/ui';
import { computed, ref, watch } from 'vue';
import AppFooter from './AppFooter.vue';
import AppSidebar from './AppSidebar.vue';
import AppTopbar from './AppTopbar.vue';
import AppSpeedDial from './AppSpeedDial.vue';
import AppBottomNav from './AppBottomNav.vue';
import TransactionModal from '@/views/modules/Transactions/components/TransactionModal.vue';

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
        <!-- Sidebar solo visible en desktop -->
        <app-sidebar v-if="!uiStore.isMobile"></app-sidebar>
        <div class="layout-main-container" :class="{ 'pb-20': uiStore.isMobile }">
            <div class="layout-main">
                <router-view v-slot="{ Component, route }">
                    <transition name="fade" mode="out-in">
                        <div :key="route.path">
                            <component :is="Component" />
                        </div>
                    </transition>
                </router-view>
            </div>
            <app-footer v-if="!uiStore.isMobile"></app-footer>
            <!-- SpeedDial solo en desktop -->
            <app-speed-dial v-if="!uiStore.isMobile"></app-speed-dial>
        </div>
        <transaction-modal></transaction-modal>
        <!-- Bottom nav solo en mobile -->
        <app-bottom-nav v-if="uiStore.isMobile"></app-bottom-nav>
        <div 
            v-if="uiStore.layoutState.overlayMenuActive || uiStore.layoutState.staticMenuMobileActive" 
            class="layout-mask animate-fadein"
            @click="onMaskClick"
        ></div>
    </div>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
    transition: opacity 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
    opacity: 0;
}
</style>
