<script setup>
import { useUIStore } from '@/stores/ui';
import { onBeforeMount, ref, watch, computed } from 'vue';
import { useRoute } from 'vue-router';

const route = useRoute();
const uiStore = useUIStore();

const props = defineProps({
    item: {
        type: Object,
        default: () => ({})
    },
    index: {
        type: Number,
        default: 0
    },
    root: {
        type: Boolean,
        default: true
    },
    parentItemKey: {
        type: String,
        default: null
    }
});

const isActiveMenu = ref(false);
const itemKey = ref(null);

onBeforeMount(() => {
    itemKey.value = props.parentItemKey ? props.parentItemKey + '-' + props.index : String(props.index);

    const activeItem = uiStore.layoutState.activeMenuItem;

    isActiveMenu.value = activeItem === itemKey.value || activeItem ? activeItem.startsWith(itemKey.value + '-') : false;
});

watch(
    () => uiStore.layoutState.activeMenuItem,
    (newVal) => {
        isActiveMenu.value = newVal === itemKey.value || newVal?.startsWith(itemKey.value + '-');
    }
);

function itemClick(event, item) {
    if (item.disabled) {
        event.preventDefault();
        return;
    }

    // Si es un enlace (to o url) y hay menú overlay/mobile activo, ocultarlo
    if ((item.to || item.url) && (uiStore.layoutState.staticMenuMobileActive || uiStore.layoutState.overlayMenuActive)) {
        uiStore.hideMenu();
    }

    if (item.command) {
        item.command({ originalEvent: event, item: item });
    }

    const foundItemKey = item.items ? (isActiveMenu.value ? props.parentItemKey : itemKey) : itemKey.value;

    uiStore.setActiveMenuItem(foundItemKey);
}

function checkActiveRoute(item) {
    return route.path === item.to;
}
</script>

<template>
    <li :class="{ 'layout-root-menuitem': root, 'active-menuitem': isActiveMenu }">
        <div v-if="root && item.visible !== false" class="layout-menuitem-root-text">{{ item.label }}</div>
        <a v-if="(!item.to || item.items) && item.visible !== false" :href="item.url"
            @click="itemClick($event, item, index)" :class="item.class" :target="item.target" tabindex="0">
            <!-- Icono para elementos sin ruta -->
            <i v-if="item.primeicon" :class="[item.icon, 'layout-menuitem-icon']"></i>
            <span v-else class="material-symbols-outlined layout-menuitem-icon">{{ item.icon }}</span>
            <span class="layout-menuitem-text">{{ item.label }}</span>
            <i v-if="item.items" class="pi pi-fw pi-angle-down layout-submenu-toggler"></i>
        </a>
        <router-link v-if="item.to && !item.items && item.visible !== false" @click="itemClick($event, item, index)"
            :class="[item.class, { 'active-route': checkActiveRoute(item) }]" tabindex="0" :to="item.to">
            <!-- Icono para elementos con ruta -->
            <i v-if="item.primeicon" :class="[item.icon, 'layout-menuitem-icon']"></i>
            <span v-else class="material-symbols-outlined layout-menuitem-icon">{{ item.icon }}</span>
            <span class="layout-menuitem-text">{{ item.label }}</span>
            <i v-if="item.items" class="pi pi-fw pi-angle-down layout-submenu-toggler"></i>
        </router-link>
        <Transition v-if="item.items && item.visible !== false" name="layout-submenu">
            <ul v-show="root ? true : isActiveMenu" class="layout-submenu">
                <app-menu-item v-for="(child, i) in item.items" :key="i" :index="i" :item="child"
                    :parentItemKey="itemKey" :root="false"></app-menu-item>
            </ul>
        </Transition>
    </li>
</template>

<style lang="scss" scoped>
.material-symbols-outlined {
    font-variation-settings:
        'FILL' 0,
        'wght' 400,
        'GRAD' 0,
        'opsz' 24;
    font-size: 1.25rem;
    line-height: 1;
    vertical-align: middle;
}
</style>
