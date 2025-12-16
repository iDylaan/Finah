import { ref } from 'vue';
import { defineStore } from 'pinia';
import { supabase } from '@/lib/supabase.js';
import { handleError } from '@/lib/utils.js';

export const useCategoriesStore = defineStore('categories', () => {
    // Estados
    const categories = ref([]);
    const categoryGroups = ref([]);
    const loading = ref(false);
    const loaded = ref(false);
    const lastFetchTime = ref(null);

    // FUNCIONES PARA CATEGORÍAS
    
    // Función para obtener categorías (públicas + del usuario)
    const fetchCategories = async ({ toast, force = false }) => {
        // Si ya tenemos datos y no es forzado, simplemente regresamos los datos actuales
        if (loaded.value && categories.value.length > 0 && !force) {
            console.log('🔄 Usando datos de categorías en caché');
            return categories.value;
        }
        
        loading.value = true;

        try {
            console.log('🔍 Consultando categorías desde la base de datos');
            const { data: { user } } = await supabase.auth.getUser();
            const userId = user?.id;

            let query = supabase
                .from('categorias')
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
                return [];
            } else {
                categories.value = data || [];
                loaded.value = true;
                lastFetchTime.value = Date.now();
                return categories.value;
            }

        } catch (error) {
            handleError(error, toast);
            return [];
        } finally {
            loading.value = false;
        }
    };

    // Función para crear una nueva categoría
    const createCategory = async (categoryData, { toast }) => {
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

            // Validar que la categoría tenga un grupo asignado
            if (!categoryData.group_id) {
                throw new Error('La categoría debe pertenecer a un grupo')
            }

            // Preparar datos para insertar
            const insertData = {
                nombre: categoryData.name,
                descripcion: categoryData.description || null,
                nombre_icono: categoryData.icon_name || 'pi pi-tag',
                biblioteca_iconos: categoryData.icon_type || 'primeicons',
                es_publico: false, // Por defecto, las categorías creadas por usuarios son privadas
                usuario_id: user.id,
                grupo_id: categoryData.group_id
            }

            // Insertar en la base de datos
            const { data, error } = await supabase
                .from('categorias')
                .insert([insertData])
                .select() // Retornar el registro insertado

            if (error) {
                console.error('💥 Error insertando categoría:', error)
                throw error
            }

            // Actualizar el estado local agregando la nueva categoría
            if (data && data[0]) {
                // Agregar a la lista plana de categorías
                categories.value.unshift(data[0])

                // Agregar la categoría al grupo correspondiente en el estado anidado
                const groupIndex = categoryGroups.value.findIndex(g => g.id === categoryData.group_id)
                if (groupIndex !== -1) {
                    categoryGroups.value[groupIndex].categories.unshift(data[0])
                }
            }

            // Mostrar mensaje de éxito
            toast.add({
                severity: 'success',
                summary: 'Categoría Creada',
                detail: `La categoría "${categoryData.name}" se creó exitosamente`,
                life: 3000
            })

            return data[0] // Retornar la categoría creada

        } catch (error) {
            console.error('💥 Error creando categoría:', error)

            // Mostrar mensaje de error
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Error creando la categoría',
                life: 5000
            })

            throw error // Re-lanzar para manejo en el componente

        } finally {
            loading.value = false
        }
    }

    // Función para actualizar una categoría
    const updateCategory = async (categoryId, categoryData, { toast }) => {
        loading.value = true

        try {
            // Obtener el usuario actual
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }

            // Preparar datos para actualizar
            const updateData = {
                nombre: categoryData.name,
                descripcion: categoryData.description || null,
                nombre_icono: categoryData.icon_name || 'pi pi-tag',
                biblioteca_iconos: categoryData.icon_type || 'primeicons',
                grupo_id: categoryData.group_id
                // No incluimos es_publico ni usuario_id ya que no deben cambiarse en una actualización
            }

            // Actualizar en la base de datos
            const { data, error } = await supabase
                .from('categorias')
                .update(updateData)
                .eq('id', categoryId)
                .eq('usuario_id', user.id) // Asegurar que solo el dueño pueda actualizarla
                .select()

            if (error) {
                console.error('💥 Error actualizando categoría:', error)
                throw error
            }

            if (!data || data.length === 0) {
                throw new Error('No se pudo actualizar la categoría. Verifica que sea tuya y no sea pública.')
            }

            // Actualizar el estado local
            const updatedCategory = data[0]
            
            // Actualizar en la lista plana de categorías
            const categoryIndex = categories.value.findIndex(c => c.id === categoryId)
            if (categoryIndex !== -1) {
                categories.value[categoryIndex] = {
                    ...categories.value[categoryIndex],
                    ...updatedCategory
                }
            }

            // Actualizar en la estructura de grupos con categorías
            // Primero verificar si la categoría está cambiando de grupo
            const oldGroupId = categories.value[categoryIndex]?.group_id
            const newGroupId = updatedCategory.group_id
            
            if (oldGroupId !== newGroupId) {
                // Si está cambiando de grupo, quitar de uno y agregar al otro
                
                // Quitar del grupo antiguo
                const oldGroupIndex = categoryGroups.value.findIndex(g => g.id === oldGroupId)
                if (oldGroupIndex !== -1) {
                    categoryGroups.value[oldGroupIndex].categories = 
                        categoryGroups.value[oldGroupIndex].categories.filter(c => c.id !== categoryId)
                }
                
                // Agregar al nuevo grupo
                const newGroupIndex = categoryGroups.value.findIndex(g => g.id === newGroupId)
                if (newGroupIndex !== -1) {
                    categoryGroups.value[newGroupIndex].categories.unshift(updatedCategory)
                }
            } else {
                // Si sigue en el mismo grupo, simplemente actualizar
                const groupIndex = categoryGroups.value.findIndex(g => g.id === newGroupId)
                if (groupIndex !== -1) {
                    const catIndex = categoryGroups.value[groupIndex].categories.findIndex(c => c.id === categoryId)
                    if (catIndex !== -1) {
                        categoryGroups.value[groupIndex].categories[catIndex] = {
                            ...categoryGroups.value[groupIndex].categories[catIndex],
                            ...updatedCategory
                        }
                    }
                }
            }

            // Mostrar mensaje de éxito
            toast.add({
                severity: 'success',
                summary: 'Categoría Actualizada',
                detail: `La categoría "${categoryData.name}" se actualizó exitosamente`,
                life: 3000
            })

            return updatedCategory

        } catch (error) {
            console.error('💥 Error actualizando categoría:', error)

            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Error actualizando la categoría',
                life: 5000
            })

            throw error

        } finally {
            loading.value = false
        }
    }

    // Función para eliminar una categoría
    const deleteCategory = async (categoryId, { toast }) => {
        loading.value = true

        try {
            // Obtener el usuario actual
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }

            // Buscar la categoría para saber a qué grupo pertenece (antes de eliminarla)
            const categoryToDelete = categories.value.find(c => c.id === categoryId)
            const groupId = categoryToDelete?.grupo_id

            // Eliminar de la base de datos
            const { error } = await supabase
                .from('categorias')
                .delete()
                .eq('id', categoryId)
                .eq('usuario_id', user.id) // Solo el dueño puede eliminar

            if (error) {
                console.error('💥 Error eliminando categoría:', error)
                throw error
            }
            
            // Actualizar los estados locales
            // 1. Quitar de la lista plana de categorías
            categories.value = categories.value.filter(c => c.id !== categoryId)
            
            // 2. Quitar de la estructura anidada de grupos
            if (groupId) {
                const groupIndex = categoryGroups.value.findIndex(g => g.id === groupId)
                if (groupIndex !== -1) {
                    categoryGroups.value[groupIndex].categories = 
                        categoryGroups.value[groupIndex].categories.filter(c => c.id !== categoryId)
                }
            }

            // Mostrar mensaje de éxito
            toast.add({
                severity: 'success',
                summary: 'Categoría Eliminada',
                detail: `La categoría ha sido eliminada exitosamente`,
                life: 3000
            })

            return true

        } catch (error) {
            console.error('💥 Error eliminando categoría:', error)

            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Error eliminando la categoría',
                life: 5000
            })

            throw error

        } finally {
            loading.value = false
        }
    }

    // Función genérica para guardar categoría (crear o actualizar)
    const saveCategory = async (categoryData, isEdit = false, { toast }) => {
        if (isEdit && categoryData.id) {
            return await updateCategory(categoryData.id, categoryData, { toast })
        } else {
            return await createCategory(categoryData, { toast })
        }
    }

    // FUNCIONES PARA GRUPOS DE CATEGORÍAS
    
    // Función para obtener grupos de categorías (públicos + del usuario)
    const fetchCategoryGroups = async ({ toast }) => {
        loading.value = true

        try {
            const { data: { user } } = await supabase.auth.getUser()
            const userId = user?.id

            let query = supabase
                .from('grupos_categoria')
                .select('*')

            if (userId) {
                // Mostrar públicos O del usuario actual
                query = query.or(`es_publico.eq.true,usuario_id.eq.${userId}`)
            } else {
                // Solo públicos si no hay usuario
                query = query.eq('es_publico', true)
            }

            const { data, error } = await query

            if (error) {
                handleError(error, toast)
            } else {
                categoryGroups.value = data || []
            }

        } catch (error) {
            handleError(error, toast)
        } finally {
            loading.value = false
        }
    }

    // Función para obtener category_groups con sus categorías anidadas
    const fetchCategoryGroupsWithCategories = async ({ toast, force = false }) => {
        // Si ya tenemos datos y no es forzado, simplemente regresamos los datos actuales
        if (loaded.value && categoryGroups.value.length > 0 && !force) {
            console.log('🔄 Usando datos de grupos y categorías en caché');
            return categoryGroups.value;
        }
        
        loading.value = true;

        try {
            console.log('🔍 Consultando grupos y categorías desde la base de datos');
            const { data: { user } } = await supabase.auth.getUser();
            const userId = user?.id;

            // **PASO 1:** Obtener todas las categorías primero
            let categoriesQuery = supabase
                .from('categorias')
                .select('*')

            if (userId) {
                categoriesQuery = categoriesQuery.or(`es_publico.eq.true,usuario_id.eq.${userId}`)
            } else {
                categoriesQuery = categoriesQuery.eq('es_publico', true)
            }

            const { data: categoriesData, error: categoriesError } = await categoriesQuery

            if (categoriesError) {
                handleError(categoriesError, toast)
                return
            }

            // **PASO 2:** Obtener todos los grupos de categorías
            let groupsQuery = supabase
                .from('grupos_categoria')
                .select('*')

            if (userId) {
                groupsQuery = groupsQuery.or(`es_publico.eq.true,usuario_id.eq.${userId}`)
            } else {
                groupsQuery = groupsQuery.eq('es_publico', true)
            }

            const { data: groupsData, error: groupsError } = await groupsQuery

            if (groupsError) {
                handleError(groupsError, toast)
                return
            }

            // **PASO 3:** Ordenar categorías (Privadas primero, luego alfabético)
            const sortedCategories = categoriesData.sort((a, b) => {
                // Primero: Privadas (false) antes que públicas (true)
                if (a.es_publico !== b.es_publico) {
                    return a.es_publico - b.es_publico // false (0) < true (1)
                }
                // Segundo: Orden alfabético por nombre (case insensitive)
                return a.nombre.toLowerCase().localeCompare(b.nombre.toLowerCase())
            })

            // **PASO 4:** Agrupar categorías ordenadas por grupo_id
            const categoriesByGroup = {}
            sortedCategories.forEach(category => {
                const groupId = category.grupo_id
                if (!categoriesByGroup[groupId]) {
                    categoriesByGroup[groupId] = []
                }
                categoriesByGroup[groupId].push(category)
            })

            // **PASO 5:** Ordenar grupos (Privados primero, luego alfabético)
            const sortedGroups = groupsData.sort((a, b) => {
                // Primero: Privadas (false) antes que públicas (true)
                if (a.es_publico !== b.es_publico) {
                    return a.es_publico - b.es_publico // false (0) < true (1)
                }
                // Segundo: Orden alfabético por nombre (case insensitive)
                return a.nombre.toLowerCase().localeCompare(b.nombre.toLowerCase())
            })

            // **PASO 6:** Agregar categorías ordenadas a cada grupo
            const groupsWithCategories = sortedGroups.map(group => ({
                ...group,
                categories: categoriesByGroup[group.id] || []
            }))

            // **PASO 7:** Actualizar estados del store
            categories.value = sortedCategories || [];
            categoryGroups.value = groupsWithCategories || [];
            loaded.value = true;
            lastFetchTime.value = Date.now();

            return groupsWithCategories

        } catch (error) {
            handleError(error, toast)
            return []
        } finally {
            loading.value = false
        }
    }

    // Función para crear un grupo de categorías
    const createCategoryGroup = async (groupData, { toast }) => {
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

            // Preparar datos para insertar
            const insertData = {
                nombre: groupData.name,
                descripcion: groupData.description || null,
                tipo: groupData.tipo || 'gasto',
                nombre_icono: groupData.icon_name || 'pi pi-folder',
                biblioteca_iconos: groupData.icon_type || 'primeicons',
                color: groupData.color || '#6366f1',
                es_publico: false, // Por defecto, los grupos creados por usuarios son privados
                usuario_id: user.id
            }

            // Insertar en la base de datos
            const { data, error } = await supabase
                .from('grupos_categoria')
                .insert([insertData])
                .select() // Retornar el registro insertado

            if (error) {
                console.error('💥 Error insertando grupo de categorías:', error)
                throw error
            }

            // Actualizar el estado local agregando el nuevo grupo
            if (data && data[0]) {
                // Añadir el nuevo grupo con un array vacío de categorías
                const newGroup = {
                    ...data[0],
                    categories: [] // Inicializar con array vacío de categorías
                }
                
                // Agregar al inicio del array de grupos
                categoryGroups.value.unshift(newGroup)
            }

            // Mostrar mensaje de éxito
            toast.add({
                severity: 'success',
                summary: 'Grupo Creado',
                detail: `El grupo "${groupData.name}" se creó exitosamente`,
                life: 3000
            })

            return data[0] // Retornar el grupo creado

        } catch (error) {
            console.error('💥 Error creando grupo de categorías:', error)

            // Mostrar mensaje de error
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Error creando el grupo de categorías',
                life: 5000
            })

            throw error // Re-lanzar para manejo en el componente

        } finally {
            loading.value = false
        }
    }

    // Función para actualizar un grupo de categorías
    const updateCategoryGroup = async (groupId, groupData, { toast }) => {
        loading.value = true

        try {
            // Obtener el usuario actual
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }

            // Preparar datos para actualizar
            const updateData = {
                nombre: groupData.name,
                descripcion: groupData.description || null,
                tipo: groupData.tipo || 'gasto',
                nombre_icono: groupData.icon_name || 'pi pi-folder',
                biblioteca_iconos: groupData.icon_type || 'primeicons',
                color: groupData.color || '#6366f1'
                // No incluimos es_publico ni usuario_id ya que no deben cambiarse en una actualización
            }

            // Actualizar en la base de datos
            const { data, error } = await supabase
                .from('grupos_categoria')
                .update(updateData)
                .eq('id', groupId)
                .eq('usuario_id', user.id) // Asegurar que solo el dueño pueda actualizarlo
                .select()

            if (error) {
                console.error('💥 Error actualizando grupo de categorías:', error)
                throw error
            }

            if (!data || data.length === 0) {
                throw new Error('No se pudo actualizar el grupo. Verifica que sea tuyo y no sea público.')
            }

            // Actualizar el estado local
            const updatedGroup = data[0]
            const groupIndex = categoryGroups.value.findIndex(g => g.id === groupId)
            
            if (groupIndex !== -1) {
                // Mantener las categorías que ya tenía el grupo
                const existingCategories = categoryGroups.value[groupIndex].categories || []
                
                // Actualizar el grupo manteniendo sus categorías
                categoryGroups.value[groupIndex] = {
                    ...updatedGroup,
                    categories: existingCategories
                }
            }

            // Mostrar mensaje de éxito
            toast.add({
                severity: 'success',
                summary: 'Grupo Actualizado',
                detail: `El grupo "${groupData.name}" se actualizó exitosamente`,
                life: 3000
            })

            return {
                ...updatedGroup,
                categories: categoryGroups.value[groupIndex]?.categories || []
            }

        } catch (error) {
            console.error('💥 Error actualizando grupo de categorías:', error)

            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Error actualizando el grupo de categorías',
                life: 5000
            })

            throw error

        } finally {
            loading.value = false
        }
    }

    // Función para eliminar un grupo de categorías y todas sus categorías asociadas
    const deleteCategoryGroup = async (groupId, { toast }) => {
        loading.value = true

        try {
            // Obtener el usuario actual
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }

            // Verificar si el grupo existe y obtener sus categorías
            const group = categoryGroups.value.find(g => g.id === groupId)
            if (!group) {
                throw new Error('El grupo no existe o ya fue eliminado')
            }

            // Verificar que el usuario sea el dueño del grupo
            if (group.es_publico || group.usuario_id !== user.id) {
                throw new Error('No tienes permiso para eliminar este grupo')
            }

            // Obtener todas las categorías del grupo
            const groupCategories = group.categories || []
            
            // Mostrar mensaje de procesamiento
            toast.add({
                severity: 'info',
                summary: 'Procesando',
                detail: `Eliminando ${groupCategories.length} categorías y el grupo "${group.nombre}"...`,
                life: 3000
            })

            // 1. Eliminar todas las categorías del grupo
            if (groupCategories.length > 0) {
                // Construir una lista de IDs de categorías del usuario actual
                const categoryIds = groupCategories
                    .filter(cat => !cat.es_publico && cat.usuario_id === user.id)
                    .map(cat => cat.id)
                
                if (categoryIds.length > 0) {
                    // Eliminar todas las categorías del usuario en una sola operación
                    const { error: deleteError } = await supabase
                        .from('categorias')
                        .delete()
                        .in('id', categoryIds)
                        .eq('usuario_id', user.id)
                    
                    if (deleteError) {
                        throw new Error(`Error eliminando categorías: ${deleteError.message}`)
                    }
                }
            }

            // 2. Eliminar el grupo
            const { error } = await supabase
                .from('grupos_categoria')
                .delete()
                .eq('id', groupId)
                .eq('usuario_id', user.id)

            if (error) {
                throw new Error(`Error eliminando grupo: ${error.message}`)
            }
            
            // 3. Actualizar el estado local
            // Quitar las categorías eliminadas del estado plano
            categories.value = categories.value.filter(c => c.grupo_id !== groupId || c.es_publico)
            
            // Quitar el grupo del estado anidado
            categoryGroups.value = categoryGroups.value.filter(g => g.id !== groupId)

            // Mostrar mensaje de éxito
            toast.add({
                severity: 'success',
                summary: 'Grupo Eliminado',
                detail: `El grupo "${group.nombre}" y sus categorías han sido eliminados exitosamente`,
                life: 3000
            })

            return true

        } catch (error) {
            console.error('💥 Error eliminando grupo de categorías:', error)

            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Error eliminando el grupo de categorías',
                life: 5000
            })

            throw error

        } finally {
            loading.value = false
        }
    }

    // Función genérica para guardar grupo (crear o actualizar)
    const saveCategoryGroup = async (groupData, isEdit = false, { toast }) => {
        if (isEdit && groupData.id) {
            return await updateCategoryGroup(groupData.id, groupData, { toast })
        } else {
            return await createCategoryGroup(groupData, { toast })
        }
    }

    // Función para forzar una reconsulta de categorías
    const refreshCategories = async ({ toast }) => {
        return await fetchCategories({ toast, force: true });
    };

    // Función para forzar una reconsulta de grupos y categorías
    const refreshCategoryGroupsWithCategories = async ({ toast }) => {
        return await fetchCategoryGroupsWithCategories({ toast, force: true });
    };

    // Función para limpiar la caché
    const clearCache = () => {
        categories.value = [];
        categoryGroups.value = [];
        loaded.value = false;
        lastFetchTime.value = null;
    };

    return {
        // Estados
        categories,
        categoryGroups,
        loading,
        loaded,
        lastFetchTime,

        // Funciones para categorías
        fetchCategories,
        refreshCategories,
        createCategory,
        updateCategory,
        deleteCategory,
        saveCategory,
        
        // Funciones para grupos de categorías
        fetchCategoryGroups,
        fetchCategoryGroupsWithCategories,
        refreshCategoryGroupsWithCategories,
        createCategoryGroup,
        updateCategoryGroup,
        deleteCategoryGroup,
        saveCategoryGroup,
        
        // Utilidades
        clearCache
    }
})