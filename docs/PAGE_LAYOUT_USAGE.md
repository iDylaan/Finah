# PageLayout Component - Guía de Uso

El componente `PageLayout` proporciona una estructura consistente para todas las páginas de la aplicación con un header responsive y slots flexibles.

## 📦 Ubicación

```
src/components/PageLayout.vue
```

## ✨ Características

- ✅ Header sticky (se mantiene fijo al hacer scroll)
- ✅ Responsive mobile/desktop
- ✅ Slots flexibles para personalización
- ✅ Props simples para uso básico
- ✅ Soporte para modo oscuro
- ✅ Botones con label oculto en mobile (clase `mobile-icon-only`)

## 🎯 Uso Básico

### Opción 1: Con Props (Más Simple)

```vue
<template>
    <PageLayout 
        title="Mi Página" 
        description="Descripción de mi página"
    >
        <!-- Botones del header -->
        <template #actions>
            <Button icon="pi pi-refresh" @click="refresh" />
            <Button icon="pi pi-plus" label="Nuevo" />
        </template>

        <!-- Contenido principal -->
        <div class="my-content">
            <!-- Tu contenido aquí -->
        </div>
    </PageLayout>
</template>

<script setup>
import PageLayout from '@/components/PageLayout.vue';

const refresh = () => {
    console.log('Refresh!');
};
</script>
```

### Opción 2: Con Slot Personalizado (Más Flexible)

```vue
<template>
    <PageLayout>
        <!-- Header personalizado -->
        <template #header>
            <div>
                <h1 class="page-title">
                    <i class="pi pi-users"></i>
                    Usuarios
                </h1>
                <p class="page-description">
                    Gestiona los usuarios del sistema
                    <Badge value="23" severity="info" class="ml-2" />
                </p>
            </div>
        </template>

        <!-- Acciones del header -->
        <template #actions>
            <Button icon="pi pi-download" label="Exportar" outlined />
            <Button icon="pi pi-plus" label="Nuevo Usuario" />
        </template>

        <!-- Contenido -->
        <DataTable :value="users" />
    </PageLayout>
</template>
```

## 📱 Botones Responsive

Para botones que muestren label en desktop pero solo icono en mobile:

```vue
<template #actions>
    <Button 
        icon="pi pi-plus" 
        label="Nuevo Grupo" 
        class="mobile-icon-only"
    />
</template>
```

En mobile (< 768px): Solo se muestra el icono ➕
En desktop (≥ 768px): Se muestra "➕ Nuevo Grupo"

## 🎨 Slots Disponibles

### `#header` (Opcional)
Contenido personalizado del header. Si no se proporciona, usa las props `title` y `description`.

```vue
<template #header>
    <div>
        <h1 class="page-title">Mi Título</h1>
        <p class="page-description">Mi descripción</p>
    </div>
</template>
```

### `#actions` (Opcional)
Botones y acciones del lado derecho del header.

```vue
<template #actions>
    <Button icon="pi pi-refresh" />
    <Button icon="pi pi-plus" label="Nuevo" />
</template>
```

### Slot por defecto
Contenido principal de la página.

```vue
<PageLayout title="...">
    <!-- Tu contenido aquí -->
    <div>Contenido principal</div>
</PageLayout>
```

## 📐 Props

| Prop | Tipo | Default | Descripción |
|------|------|---------|-------------|
| `title` | String | `''` | Título de la página |
| `description` | String | `''` | Descripción de la página |

## 🎯 Ejemplos de Uso Real

### Ejemplo 1: Módulo de Categorías (Actual)

```vue
<template>
    <PageLayout 
        title="Categorías" 
        description="Gestiona la clasificación de tus ingresos, egresos y gastos"
    >
        <template #actions>
            <Button 
                icon="pi pi-refresh" 
                @click="refreshData" 
                :loading="loading"
                severity="secondary" 
                outlined 
            />
            <Button 
                icon="pi pi-plus" 
                @click="handleNew" 
                label="Nuevo Grupo" 
                class="mobile-icon-only"
            />
        </template>

        <div v-if="loading">
            <ProgressSpinner />
        </div>
        <div v-else>
            <!-- Contenido de categorías -->
        </div>
    </PageLayout>
</template>
```

### Ejemplo 2: Módulo de Cuentas

```vue
<template>
    <PageLayout 
        title="Cuentas Bancarias" 
        description="Administra tus cuentas y saldos"
    >
        <template #actions>
            <Button icon="pi pi-filter" severity="secondary" outlined />
            <Button icon="pi pi-plus" label="Nueva Cuenta" class="mobile-icon-only" />
        </template>

        <DataTable :value="accounts" />
    </PageLayout>
</template>
```

### Ejemplo 3: Header Completamente Personalizado

```vue
<template>
    <PageLayout>
        <template #header>
            <div class="flex items-center gap-3">
                <Avatar icon="pi pi-chart-bar" size="large" />
                <div>
                    <h1 class="page-title">Dashboard</h1>
                    <p class="page-description">
                        Última actualización: {{ lastUpdate }}
                    </p>
                </div>
            </div>
        </template>

        <template #actions>
            <SelectButton v-model="view" :options="viewOptions" />
            <Button icon="pi pi-cog" text />
        </template>

        <!-- Widgets del dashboard -->
        <div class="grid">
            <div class="col-12 md:col-6 lg:col-3">
                <StatsCard />
            </div>
        </div>
    </PageLayout>
</template>
```

## 🎨 Clases CSS Disponibles

Si usas el slot `#header`, puedes usar estas clases para mantener la consistencia:

```vue
<template #header>
    <div>
        <h1 class="page-title">Título</h1>
        <p class="page-description">Descripción</p>
    </div>
</template>
```

### Clases Predefinidas:

- `.page-title` - Estilo del título (responsive)
- `.page-description` - Estilo de la descripción (responsive)

## 📱 Comportamiento Responsive

### Mobile (< 768px)
- Header se apila verticalmente
- Título: 1.5rem
- Descripción: 0.875rem
- Botones con clase `mobile-icon-only` ocultan el label
- Padding: 1rem

### Desktop (≥ 768px)
- Header en fila horizontal
- Título: 2rem
- Descripción: 1rem
- Botones muestran label completo
- Padding: 1.5rem - 2rem

## 🎯 Tips de Uso

1. **Usa props para casos simples**: Si solo necesitas título y descripción, usa las props.

2. **Usa slots para personalización**: Si necesitas iconos, badges, o estructura diferente, usa el slot `#header`.

3. **Clase `mobile-icon-only`**: Úsala en botones donde el texto es obvio (Nuevo, Guardar, etc.).

4. **Acciones consistentes**: Mantén el mismo orden de botones en todas las páginas (refresh, filtros, acción principal).

5. **Loading states**: Maneja el loading en el contenido principal, no en el header.

## 🔄 Migrar Páginas Existentes

### Antes:
```vue
<template>
    <div class="p-6">
        <div class="flex justify-between mb-6">
            <div>
                <h1>Título</h1>
                <p>Descripción</p>
            </div>
            <div>
                <Button />
            </div>
        </div>
        
        <div>Contenido</div>
    </div>
</template>
```

### Después:
```vue
<template>
    <PageLayout title="Título" description="Descripción">
        <template #actions>
            <Button />
        </template>
        
        <div>Contenido</div>
    </PageLayout>
</template>

<script setup>
import PageLayout from '@/components/PageLayout.vue';
</script>
```

## ✅ Beneficios

- ✨ Consistencia visual en todas las páginas
- 📱 Responsive automático
- 🎯 Header sticky sin esfuerzo
- 🔧 Fácil de mantener
- 🎨 Personalizable cuando se necesita
- ♿ Accesible y semántico
