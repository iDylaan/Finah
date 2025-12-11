# Sistema de Favicons con Soporte para Modo Claro y Oscuro

## Descripción

La aplicación ahora soporta favicons dinámicos que cambian automáticamente según el tema activo (modo claro/oscuro), tanto en navegadores web como en PWA.

## Archivos de Iconos

### Prefijos
- **`w_`** - Modo claro (white/light theme)
- **`b_`** - Modo oscuro (black/dark theme)

### Archivos en `/public/`
```
Modo Claro:
- w_icon.svg          - Favicon SVG para navegadores modernos
- w_favicon.ico       - Favicon ICO para navegadores antiguos
- w_apple-touch-icon.png - Icono para iOS/Apple devices
- w_android-chrome-192x192.png - Icono PWA 192x192
- w_android-chrome-512x512.png - Icono PWA 512x512

Modo Oscuro:
- b_icon.svg          - Favicon SVG para navegadores modernos
- b_favicon.ico       - Favicon ICO para navegadores antiguos
- b_apple-touch-icon.png - Icono para iOS/Apple devices
- b_android-chrome-192x192.png - Icono PWA 192x192
- b_android-chrome-512x512.png - Icono PWA 512x512
```

## Archivos de Configuración

### Web Manifests
- **`site-light.webmanifest`** - Configuración PWA para modo claro
- **`site-dark.webmanifest`** - Configuración PWA para modo oscuro
- **`site.webmanifest`** - Manifest legacy (puede eliminarse)

## Implementación Técnica

### 1. index.html
El archivo `index.html` contiene un script inline que:
- Detecta el tema inicial del `localStorage` o de `prefers-color-scheme`
- Actualiza los favicons dinámicamente cuando cambia el tema
- Sincroniza con los cambios de la clase `.app-dark` en el documento
- Actualiza el web manifest según el tema activo

### 2. UI Store (src/stores/ui.js)
El store de UI dispara un evento personalizado `themeChanged` cuando el usuario cambia el tema:
```javascript
window.dispatchEvent(new CustomEvent('themeChanged', {
    detail: { isDark: darkMode.value }
}));
```

### 3. Meta Tags Dinámicos
```html
<meta name="theme-color" content="#10b981" media="(prefers-color-scheme: light)" />
<meta name="theme-color" content="#1e293b" media="(prefers-color-scheme: dark)" />
```

## Funcionamiento

### Detección Automática
1. **Al cargar la página**: Lee la preferencia guardada en `localStorage`
2. **Fallback**: Si no hay preferencia, usa `prefers-color-scheme` del sistema
3. **Cambio manual**: Cuando el usuario cambia el tema en la app, los favicons se actualizan instantáneamente
4. **Cambio del sistema**: Si el usuario cambia el tema del sistema y no tiene preferencia guardada, se actualiza automáticamente

### Sincronización PWA
- Al instalar la PWA, usa el manifest correspondiente al tema activo
- Los iconos de la PWA se actualizan según el tema
- Los colores de `theme_color` y `background_color` se ajustan al tema

## Soporte de Plataformas

### Web (Navegadores)
- ✅ Chrome/Edge - SVG + ICO
- ✅ Firefox - SVG + ICO
- ✅ Safari - SVG + Apple Touch Icon

### PWA (Progressive Web App)
- ✅ Android - Chrome (192x192, 512x512)
- ✅ iOS - Safari (Apple Touch Icon 180x180)
- ✅ Desktop - Chrome, Edge, Safari

### Modo Offline
Los favicons funcionan offline ya que todos los archivos están en `/public/` y se sirven localmente.

## Mantenimiento

### Para actualizar los favicons:
1. Generar nuevos iconos con prefijos `w_` y `b_`
2. Reemplazar archivos en `/public/`
3. No es necesario modificar código JavaScript

### Para cambiar colores de tema:
Editar `site-light.webmanifest` y `site-dark.webmanifest`:
```json
{
  "theme_color": "#10b981",  // Color principal
  "background_color": "#ffffff"  // Color de fondo
}
```

## Notas Técnicas

- Los favicons se actualizan sin recargar la página
- El script es inline para evitar FOUC (Flash of Unstyled Content)
- Compatible con View Transitions API de Chrome
- Usa MutationObserver para detectar cambios en la clase del documento
- No requiere bibliotecas externas
