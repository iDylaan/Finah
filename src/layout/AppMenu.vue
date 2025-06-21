<script setup>
import AppMenuItem from './AppMenuItem.vue';

import { useUIStore } from '@/stores/ui';
const UI = useUIStore();

</script>

<template>
    <ul class="layout-menu">
        <template v-for="(item, i) in UI.sidebarModel" :key="item">
            <app-menu-item v-if="!item.separator" :item="item" :index="i"></app-menu-item>
            <li v-if="item.separator" class="menu-separator"></li>
        </template>
    </ul>
</template>

<style lang="scss" scoped></style>
