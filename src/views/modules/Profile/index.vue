<template>
    <div class="grid">
        <div class="col-12">
            <div class="card">
                <h5>Mi Perfil</h5>
                <p>Página de perfil del usuario (por implementar)</p>
                <div class="p-4 border-round surface-border border-1">
                    <h6>Información actual:</h6>
                    <p><strong>Email:</strong> {{ sessionStore.userEmail }}</p>
                    <p><strong>Username:</strong> {{ sessionStore.username || 'No disponible' }}</p>
                    <p><strong>Nombre completo:</strong> {{ sessionStore.fullName || 'No disponible' }}</p>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { useSessionStore } from '@/stores/session.js';

const sessionStore = useSessionStore();
</script>