<template>
    <div>
        <h1>Home</h1>
        <Button label="Submit" />
    </div>
</template>

<script setup>
// IMPORTS
import { ref, onMounted } from 'vue';

// STORES
import { useUIStore } from '@/stores/ui';
const uiStore = useUIStore();

// HOOKS
onMounted(() => {
    uiStore.setTitlePage('Inicio');
});
</script>
