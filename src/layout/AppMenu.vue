<script setup>
import { ref } from 'vue';

import AppMenuItem from './AppMenuItem.vue';

const model = ref([
    {
        label: 'Inicio',
        items: [{ label: 'Dashboard', icon: 'home', to: '/' }]
    },
    {
        label: 'UI Components',
        items: [
            { label: 'Form Layout', icon: 'assignment', to: '/uikit/formlayout' },
            { label: 'Input', icon: 'check_box', to: '/uikit/input' },
            { label: 'Button', icon: 'settings_cell', to: '/uikit/button', class: 'rotated-icon' },
            { label: 'Table', icon: 'border_all', to: '/uikit/table' },
            { label: 'List', icon: 'format_list_bulleted', to: '/uikit/list' },
            { label: 'Tree', icon: 'account_tree', to: '/uikit/tree' },
            { label: 'Panel', icon: 'home_max_dots', to: '/uikit/panel' },
            { label: 'Overlay', icon: 'ad_group', to: '/uikit/overlay' },
            { label: 'Media', icon: 'broken_image', to: '/uikit/media' },
            { label: 'Menu', icon: 'dehaze', to: '/uikit/menu' },
            { label: 'Message', icon: 'chat_bubble', to: '/uikit/message' },
            { label: 'File', icon: 'draft', to: '/uikit/file' },
            { label: 'Chart', icon: 'bar_chart', to: '/uikit/charts' },
            { label: 'Timeline', icon: 'calendar_today', to: '/uikit/timeline' },
            { label: 'Misc', icon: 'apps', to: '/uikit/misc' }
        ]
    },
    {
        label: 'Pages',
        icon: 'card_travel',
        to: '/pages',
        items: [
            {
                label: 'Landing',
                icon: 'language',
                to: '/landing'
            },
            {
                label: 'Auth',
                icon: 'identity_platform',
                items: [
                    {
                        label: 'Login',
                        icon: 'login',
                        to: '/auth/login'
                    },
                    {
                        label: 'Error',
                        icon: 'cancel',
                        to: '/auth/error'
                    },
                    {
                        label: 'Access Denied',
                        icon: 'lock',
                        to: '/auth/access'
                    }
                ]
            },
            {
                label: 'Crud',
                icon: 'edit',
                to: '/pages/crud'
            },
            {
                label: 'Not Found',
                icon: 'error',
                to: '/pages/notfound'
            },
            {
                label: 'Empty',
                icon: 'circle',
                to: '/pages/empty'
            }
        ]
    },
    // {
    //     label: 'Hierarchy',
    //     items: [
    //         {
    //             label: 'Submenu 1',
    //             icon: 'pi pi-fw pi-bookmark',
    //             items: [
    //                 {
    //                     label: 'Submenu 1.1',
    //                     icon: 'pi pi-fw pi-bookmark',
    //                     items: [
    //                         { label: 'Submenu 1.1.1', icon: 'pi pi-fw pi-bookmark' },
    //                         { label: 'Submenu 1.1.2', icon: 'pi pi-fw pi-bookmark' },
    //                         { label: 'Submenu 1.1.3', icon: 'pi pi-fw pi-bookmark' }
    //                     ]
    //                 },
    //                 {
    //                     label: 'Submenu 1.2',
    //                     icon: 'pi pi-fw pi-bookmark',
    //                     items: [{ label: 'Submenu 1.2.1', icon: 'pi pi-fw pi-bookmark' }]
    //                 }
    //             ]
    //         },
    //         {
    //             label: 'Submenu 2',
    //             icon: 'pi pi-fw pi-bookmark',
    //             items: [
    //                 {
    //                     label: 'Submenu 2.1',
    //                     icon: 'pi pi-fw pi-bookmark',
    //                     items: [
    //                         { label: 'Submenu 2.1.1', icon: 'pi pi-fw pi-bookmark' },
    //                         { label: 'Submenu 2.1.2', icon: 'pi pi-fw pi-bookmark' }
    //                     ]
    //                 },
    //                 {
    //                     label: 'Submenu 2.2',
    //                     icon: 'pi pi-fw pi-bookmark',
    //                     items: [{ label: 'Submenu 2.2.1', icon: 'pi pi-fw pi-bookmark' }]
    //                 }
    //             ]
    //         }
    //     ]
    // },
    {
        label: 'Get Started',
        items: [
            {
                label: 'Documentation',
                icon: 'integration_instructions',
                to: '/documentation'
            },
            {
                label: 'View Source',
                icon: 'pi pi-fw pi-github',
                primeicon: true,
                url: 'https://github.com/primefaces/sakai-vue',
                target: '_blank'
            }
        ]
    }
]);
</script>

<template>
    <ul class="layout-menu">
        <template v-for="(item, i) in model" :key="item">
            <app-menu-item v-if="!item.separator" :item="item" :index="i"></app-menu-item>
            <li v-if="item.separator" class="menu-separator"></li>
        </template>
    </ul>
</template>

<style lang="scss" scoped></style>
