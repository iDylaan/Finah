import { ref } from 'vue';
import { defineStore } from 'pinia';
import { supabase } from '@/lib/supabase.js';
import { handleError } from '@/lib/utils.js';
import { LEVEL_COLORS } from '@/assets/constants/levels-colors.js';

export const useLevelStore = defineStore('levels', () => {
    // Estados
    const levels = ref([]);
    const loading = ref(false);
    const loaded = ref(false);
    const lastFetchTime = ref(null);

    // Función para obtener niveles (públicos + del usuario)
    const fetchLevels = async ({ toast, force = false } = {}) => {
        // Si ya tenemos datos y no es forzado, simplemente regresamos los datos actuales
        if (loaded.value && levels.value.length > 0 && !force) {
            console.log('🔄 Usando datos de niveles en caché');
            return levels.value;
        }
        
        loading.value = true;

        try {
            console.log('🔍 Consultando niveles desde la base de datos');
            const { data: { user } } = await supabase.auth.getUser();
            const userId = user?.id;

            let query = supabase
                .from('niveles')
                .select('*');

            if (userId) {
                // Mostrar públicos O del usuario actual
                query = query.or(`es_publico.eq.true,usuario_id.eq.${userId}`);
            } else {
                // Solo públicos si no hay usuario
                query = query.eq('es_publico', true);
            }

            const { data, error } = await query;

            if (error) {
                handleError(error, toast);
            } else {
                // Ordenar: primero privados, luego por nombre
                levels.value = (data || []).sort((a, b) => {
                    // Primero: Privados (false) antes que públicos (true)
                    if (a.es_publico !== b.es_publico) {
                        return a.es_publico - b.es_publico; // false (0) < true (1)
                    }
                    // Segundo: Orden alfabético por nombre
                    return a.nombre.toLowerCase().localeCompare(b.nombre.toLowerCase());
                });
                loaded.value = true;
                lastFetchTime.value = Date.now();
            }
            
            return levels.value;

        } catch (error) {
            handleError(error, toast);
            return [];
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
        loading.value = true

        try {
            // Obtener el usuario actual
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError) {
                throw new Error('Error obteniendo usuario: ' + userError.message)
            }

            if (!user) {
                throw new Error('Usuario no autenticado')
            }

            // Preparar datos para insertar - aplicando trim
            const insertData = {
                nombre: levelData.name.trim(),
                color: levelData.colorKey.trim(), // Aplicar trim al color
                es_publico: false, // Por defecto, los niveles creados por usuarios son privados
                usuario_id: user.id
            }

            // Insertar en la base de datos
            const { data, error } = await supabase
                .from('niveles')
                .insert([insertData])
                .select() // Retornar el registro insertado

            if (error) {
                console.error('💥 Error insertando nivel:', error)
                throw error
            }

            // Actualizar el estado local agregando el nuevo nivel
            if (data && data[0]) {
                levels.value.unshift(data[0])
            }

            // Mostrar mensaje de éxito
            toast.add({
                severity: 'success',
                summary: 'Nivel Creado',
                detail: `El nivel "${levelData.name}" se creó exitosamente`,
                life: 3000
            })

            return data[0] // Retornar el nivel creado

        } catch (error) {
            console.error('💥 Error creando nivel:', error)

            // Mostrar mensaje de error
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Error creando el nivel',
                life: 5000
            })

            throw error // Re-lanzar para manejo en el componente

        } finally {
            loading.value = false
        }
    }

    // Función para actualizar un nivel
    const updateLevel = async (levelId, levelData, { toast }) => {
        loading.value = true

        try {
            // Obtener el usuario actual
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }

            // Preparar datos para actualizar - aplicando trim
            const updateData = {
                nombre: levelData.name.trim(),
                color: levelData.colorKey.trim() // Aplicar trim al color
                // No incluimos es_publico ni usuario_id ya que no deben cambiarse en una actualización
            }

            // Actualizar en la base de datos
            const { data, error } = await supabase
                .from('niveles')
                .update(updateData)
                .eq('id', levelId)
                .eq('usuario_id', user.id) // Asegurar que solo el dueño pueda actualizarlo
                .select()

            if (error) {
                console.error('💥 Error actualizando nivel:', error)
                throw error
            }

            if (!data || data.length === 0) {
                throw new Error('No se pudo actualizar el nivel. Verifica que sea tuyo y no sea público.')
            }

            // Actualizar el estado local
            const updatedLevel = data[0]
            const levelIndex = levels.value.findIndex(l => l.id === levelId)
            
            if (levelIndex !== -1) {
                levels.value[levelIndex] = {
                    ...levels.value[levelIndex],
                    ...updatedLevel
                }
            }

            // Mostrar mensaje de éxito
            toast.add({
                severity: 'success',
                summary: 'Nivel Actualizado',
                detail: `El nivel "${levelData.name}" se actualizó exitosamente`,
                life: 3000
            })

            return updatedLevel

        } catch (error) {
            console.error('💥 Error actualizando nivel:', error)

            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Error actualizando el nivel',
                life: 5000
            })

            throw error

        } finally {
            loading.value = false
        }
    }

    // Función para eliminar un nivel
    const deleteLevel = async (levelId, { toast }) => {
        loading.value = true

        try {
            // Obtener el usuario actual
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }

            // Eliminar de la base de datos
            const { error } = await supabase
                .from('niveles')
                .delete()
                .eq('id', levelId)
                .eq('usuario_id', user.id) // Solo el dueño puede eliminar

            if (error) {
                console.error('💥 Error eliminando nivel:', error)
                throw error
            }
            
            // Actualizar el estado local
            levels.value = levels.value.filter(l => l.id !== levelId)

            // Mostrar mensaje de éxito
            toast.add({
                severity: 'success',
                summary: 'Nivel Eliminado',
                detail: `El nivel ha sido eliminado exitosamente`,
                life: 3000
            })

            return true

        } catch (error) {
            console.error('💥 Error eliminando nivel:', error)

            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Error eliminando el nivel',
                life: 5000
            })

            throw error

        } finally {
            loading.value = false
        }
    }

    // Función genérica para guardar nivel (crear o actualizar)
    const saveLevel = async (levelData, isEdit = false, { toast }) => {
        if (isEdit && levelData.id) {
            return await updateLevel(levelData.id, levelData, { toast })
        } else {
            return await createLevel(levelData, { toast })
        }
    }

    // Función para limpiar la caché
    const clearCache = () => {
        levels.value = [];
        loaded.value = false;
        lastFetchTime.value = null;
    };

    return {
        // Estados
        levels,
        loading,
        loaded,
        lastFetchTime,

        // Funciones
        fetchLevels,
        refreshLevels,
        createLevel,
        updateLevel,
        deleteLevel,
        saveLevel,
        clearCache
    }
})