import { ref } from 'vue';
import { defineStore } from 'pinia';
import { supabase } from '@/lib/supabase.js';
import { handleError } from '@/lib/utils.js';
import { LEVEL_COLORS } from '@/assets/constants/levels-colors.js';

// Store actualizado para manejar jerarquías personalizadas
export const useLevelStore = defineStore('levels', () => {
    const levels = ref([]);
    const loading = ref(false);
    const loaded = ref(false);
    const lastFetchTime = ref(null);

    // Función para obtener niveles con jerarquía personalizada
    const fetchLevels = async ({ toast = null, force = false } = {}) => {
        // Si ya tenemos datos y no es forzado, simplemente regresamos los datos actuales
        if (loaded.value && levels.value.length > 0 && !force) {
            console.log('🔄 Usando datos de niveles en caché');
            return levels.value;
        }
        
        loading.value = true;

        try {
            console.log('🔍 Consultando niveles desde la base de datos');
            const { data: { user } } = await supabase.auth.getUser();
            
            if (!user) {
                // Usuario no autenticado: solo niveles públicos
                const { data, error } = await supabase
                    .from('niveles')
                    .select('*')
                    .eq('es_publico', true)
                    .order('jerarquia');
                
                if (error) throw error;
                levels.value = data || [];
            } else {
                // Usuario autenticado: usar función para obtener jerarquía personalizada
                const { data, error } = await supabase
                    .rpc('obtener_niveles_usuario', { p_usuario_id: user.id });
                
                if (error) throw error;
                levels.value = data || [];
            }
            
            loaded.value = true;
            lastFetchTime.value = Date.now();
            return levels.value;

        } catch (error) {
            console.error('Error fetching levels:', error);
            if (toast) {
                toast.add({
                    severity: 'error',
                    summary: 'Error',
                    detail: 'Error al cargar los niveles',
                    life: 5000
                });
            } else {
                console.error('⚠️ Error cargando niveles:', error.message);
            }
            throw error;
        } finally {
            loading.value = false;
        }
    };

    // Función para forzar una reconsulta de niveles
    const refreshLevels = async ({ toast }) => {
        return await fetchLevels({ toast, force: true });
    };

    // Función para crear un nuevo nivel
    const createLevel = async (levelData, { toast }) => {
        loading.value = true;

        try {
            // Obtener el usuario actual
            const { data: { user }, error: userError } = await supabase.auth.getUser();

            if (userError) {
                throw new Error('Error obteniendo usuario: ' + userError.message);
            }

            if (!user) {
                throw new Error('Usuario no autenticado');
            }

            // Obtener la siguiente jerarquía disponible
            const nextHierarchy = await getNextHierarchy(user.id);

            // Preparar datos para insertar
            const insertData = {
                nombre: levelData.name.trim(),
                color: levelData.colorKey.trim(),
                es_publico: false, // Por defecto, los niveles creados por usuarios son privados
                usuario_id: user.id,
                jerarquia: nextHierarchy
            };

            // Insertar en la base de datos
            const { data, error } = await supabase
                .from('niveles')
                .insert([insertData])
                .select();

            if (error) {
                console.error('💥 Error insertando nivel:', error);
                throw error;
            }

            // El trigger auto_inicializar_jerarquias se encargará de crear la jerarquía personalizada
            
            // Recargar niveles para obtener la jerarquía actualizada
            await refreshLevels({ toast });

            // Mostrar mensaje de éxito
            toast.add({
                severity: 'success',
                summary: 'Nivel Creado',
                detail: `El nivel "${levelData.name}" se creó exitosamente`,
                life: 3000
            });

            return data[0];

        } catch (error) {
            console.error('💥 Error creando nivel:', error);

            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Error creando el nivel',
                life: 5000
            });

            throw error;

        } finally {
            loading.value = false;
        }
    };

    // Función para actualizar un nivel
    const updateLevel = async (levelId, levelData, { toast }) => {
        loading.value = true;

        try {
            // Obtener el usuario actual
            const { data: { user }, error: userError } = await supabase.auth.getUser();

            if (userError || !user) {
                throw new Error('Usuario no autenticado');
            }

            // Preparar datos para actualizar
            const updateData = {
                nombre: levelData.name.trim(),
                color: levelData.colorKey.trim()
            };

            // Actualizar en la base de datos
            const { data, error } = await supabase
                .from('niveles')
                .update(updateData)
                .eq('id', levelId)
                .eq('usuario_id', user.id) // Asegurar que solo el dueño pueda actualizarlo
                .select();

            if (error) {
                console.error('💥 Error actualizando nivel:', error);
                throw error;
            }

            if (!data || data.length === 0) {
                throw new Error('No se pudo actualizar el nivel. Verifica que sea tuyo y no sea público.');
            }

            // Actualizar el estado local
            const updatedLevel = data[0];
            const levelIndex = levels.value.findIndex(l => l.id === levelId);
            
            if (levelIndex !== -1) {
                levels.value[levelIndex] = {
                    ...levels.value[levelIndex],
                    ...updatedLevel
                };
            }

            toast.add({
                severity: 'success',
                summary: 'Nivel Actualizado',
                detail: `El nivel "${levelData.name}" se actualizó exitosamente`,
                life: 3000
            });

            return updatedLevel;

        } catch (error) {
            console.error('💥 Error actualizando nivel:', error);

            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Error actualizando el nivel',
                life: 5000
            });

            throw error;

        } finally {
            loading.value = false;
        }
    };

    // Función para eliminar un nivel
    const deleteLevel = async (levelId, { toast }) => {
        loading.value = true;

        try {
            // Obtener el usuario actual
            const { data: { user }, error: userError } = await supabase.auth.getUser();

            if (userError || !user) {
                throw new Error('Usuario no autenticado');
            }

            // Eliminar de la base de datos
            const { error } = await supabase
                .from('niveles')
                .delete()
                .eq('id', levelId)
                .eq('usuario_id', user.id); // Solo el dueño puede eliminar

            if (error) {
                console.error('💥 Error eliminando nivel:', error);
                throw error;
            }
            
            // Actualizar el estado local
            levels.value = levels.value.filter(l => l.id !== levelId);

            toast.add({
                severity: 'success',
                summary: 'Nivel Eliminado',
                detail: `El nivel ha sido eliminado exitosamente`,
                life: 3000
            });

            return true;

        } catch (error) {
            console.error('💥 Error eliminando nivel:', error);

            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Error eliminando el nivel',
                life: 5000
            });

            throw error;

        } finally {
            loading.value = false;
        }
    };

    // Función genérica para guardar nivel (crear o actualizar)
    const saveLevel = async (levelData, isEdit = false, { toast }) => {
        if (isEdit && levelData.id) {
            return await updateLevel(levelData.id, levelData, { toast });
        } else {
            return await createLevel(levelData, { toast });
        }
    };

    // Función para reordenar niveles (solo actualiza jerarquías personalizadas)
    const reorderLevels = async (reorderedLevels, { toast }) => {
        loading.value = true;

        try {
            const { data: { user } } = await supabase.auth.getUser();
            
            if (!user) {
                throw new Error('Usuario no autenticado');
            }

            // Filtrar solo niveles que el usuario puede reordenar
            const userLevels = reorderedLevels.filter(level => 
                !level.es_publico && level.usuario_id === user.id
            );

            if (userLevels.length === 0) {
                toast.add({
                    severity: 'warn',
                    summary: 'Sin cambios',
                    detail: 'No hay niveles privados para reordenar',
                    life: 3000
                });
                return true;
            }

            // Actualizar jerarquías personalizadas
            const updates = reorderedLevels.map((level, index) => ({
                usuario_id: user.id,
                nivel_id: level.id,
                jerarquia_personalizada: index + 1,
                fecha_actualizacion: new Date().toISOString()
            }));

            // Usar upsert para actualizar o crear jerarquías
            const { error } = await supabase
                .from('jerarquias_usuario')
                .upsert(updates, { 
                    onConflict: 'usuario_id,nivel_id',
                    ignoreDuplicates: false 
                });

            if (error) throw error;

            // Actualizar estado local
            levels.value = reorderedLevels.map((level, index) => ({
                ...level,
                jerarquia_personalizada: index + 1
            }));

            toast.add({
                severity: 'success',
                summary: 'Orden actualizado',
                detail: 'La jerarquía personalizada se guardó correctamente',
                life: 3000
            });

            return true;

        } catch (error) {
            console.error('Error reordering levels:', error);
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Error al reordenar los niveles',
                life: 5000
            });
            throw error;
        } finally {
            loading.value = false;
        }
    };

    // Función para obtener la siguiente jerarquía disponible
    const getNextHierarchy = async (userId = null) => {
        const { data: { user } } = await supabase.auth.getUser();
        const currentUserId = userId || user?.id;
        
        if (!currentUserId) return 1;

        const { data, error } = await supabase
            .from('jerarquias_usuario')
            .select('jerarquia_personalizada')
            .eq('usuario_id', currentUserId)
            .order('jerarquia_personalizada', { ascending: false })
            .limit(1);

        if (error) {
            console.error('Error obteniendo jerarquía:', error);
            return 1;
        }

        return data.length > 0 ? (data[0].jerarquia_personalizada || 0) + 1 : 1;
    };

    // Función para marcar/desmarcar favoritos
    const toggleFavorite = async (levelId, { toast }) => {
        try {
            const { data: { user } } = await supabase.auth.getUser();
            if (!user) throw new Error('Usuario no autenticado');

            const currentLevel = levels.value.find(l => l.id === levelId);
            const newFavoriteStatus = !currentLevel.es_favorito;

            const { error } = await supabase
                .from('jerarquias_usuario')
                .update({ 
                    es_favorito: newFavoriteStatus,
                    fecha_actualizacion: new Date().toISOString()
                })
                .eq('usuario_id', user.id)
                .eq('nivel_id', levelId);

            if (error) throw error;

            // Actualizar estado local
            const levelIndex = levels.value.findIndex(l => l.id === levelId);
            if (levelIndex !== -1) {
                levels.value[levelIndex].es_favorito = newFavoriteStatus;
            }

            toast.add({
                severity: 'success',
                summary: newFavoriteStatus ? 'Favorito añadido' : 'Favorito removido',
                detail: `El nivel se ${newFavoriteStatus ? 'añadió a' : 'removió de'} favoritos`,
                life: 3000
            });

        } catch (error) {
            console.error('Error toggling favorite:', error);
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: 'Error al actualizar favoritos',
                life: 5000
            });
        }
    };

    // Función para ocultar/mostrar niveles
    const toggleVisibility = async (levelId, { toast }) => {
        try {
            const { data: { user } } = await supabase.auth.getUser();
            if (!user) throw new Error('Usuario no autenticado');

            const currentLevel = levels.value.find(l => l.id === levelId);
            const newVisibilityStatus = !currentLevel.visible;

            const { error } = await supabase
                .from('jerarquias_usuario')
                .update({ 
                    visible: newVisibilityStatus,
                    fecha_actualizacion: new Date().toISOString()
                })
                .eq('usuario_id', user.id)
                .eq('nivel_id', levelId);

            if (error) throw error;

            // Actualizar estado local
            if (newVisibilityStatus) {
                const levelIndex = levels.value.findIndex(l => l.id === levelId);
                if (levelIndex !== -1) {
                    levels.value[levelIndex].visible = newVisibilityStatus;
                }
            } else {
                // Remover de la lista si se oculta
                levels.value = levels.value.filter(l => l.id !== levelId);
            }

            toast.add({
                severity: 'success',
                summary: newVisibilityStatus ? 'Nivel mostrado' : 'Nivel oculto',
                detail: `El nivel se ${newVisibilityStatus ? 'mostró' : 'ocultó'} correctamente`,
                life: 3000
            });

        } catch (error) {
            console.error('Error toggling visibility:', error);
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: 'Error al cambiar visibilidad',
                life: 5000
            });
        }
    };

    // Función para limpiar la caché
    const clearCache = () => {
        levels.value = [];
        loaded.value = false;
        lastFetchTime.value = null;
    };

    // Función para restaurar jerarquía original
    const restoreOriginalHierarchy = async ({ toast }) => {
        try {
            const { data: { user } } = await supabase.auth.getUser();
            if (!user) throw new Error('Usuario no autenticado');

            // Eliminar todas las jerarquías personalizadas del usuario
            const { error } = await supabase
                .from('jerarquias_usuario')
                .delete()
                .eq('usuario_id', user.id);

            if (error) throw error;

            // Recargar niveles para obtener la jerarquía original
            await refreshLevels({ toast });

            toast.add({
                severity: 'success',
                summary: 'Jerarquía restaurada',
                detail: 'Se restauró la jerarquía original de los niveles',
                life: 3000
            });

        } catch (error) {
            console.error('Error restoring hierarchy:', error);
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: 'Error al restaurar la jerarquía original',
                life: 5000
            });
        }
    };

    return {
        // Estados
        levels,
        loading,
        loaded,
        lastFetchTime,

        // Funciones principales
        fetchLevels,
        refreshLevels,
        createLevel,
        updateLevel,
        deleteLevel,
        saveLevel,
        
        // Funciones de jerarquía
        reorderLevels,
        getNextHierarchy,
        restoreOriginalHierarchy,
        
        // Utilidades
        clearCache
    };
});