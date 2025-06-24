import { ref } from 'vue'
import { defineStore } from 'pinia'
import { supabase } from '@/lib/supabase.js'
import { handleError } from '@/lib/utils.js'

export const useCategoriesStore = defineStore('categories', () => {
    // Estados
    const categoryGroups = ref([])
    const categories = ref([])
    const loading = ref(false)

    // Función para obtener grupos de categorías (públicos + del usuario)
    const fetchCategoryGroups = async ({ toast }) => {
        loading.value = true
        
        try {
            const { data: { user } } = await supabase.auth.getUser()
            const userId = user?.id
            
            let query = supabase
                .from('category_groups')
                .select('*')
            
            if (userId) {
                // Mostrar públicos O del usuario actual
                query = query.or(`is_public.eq.true,user_id.eq.${userId}`)
            } else {
                // Solo públicos si no hay usuario
                query = query.eq('is_public', true)
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

    // Función para obtener categorías (públicas + del usuario)
    const fetchCategories = async ({ toast }) => {
        loading.value = true
        
        try {
            const { data: { user } } = await supabase.auth.getUser()
            const userId = user?.id
            
            let query = supabase
                .from('categories')
                .select('*')
            
            if (userId) {
                // Mostrar públicos O del usuario actual
                query = query.or(`is_public.eq.true,user_id.eq.${userId}`)
            } else {
                // Solo públicos si no hay usuario
                query = query.eq('is_public', true)
            }
            
            const { data, error } = await query
            
            if (error) {
                handleError(error, toast)
            } else {
                categories.value = data || []
            }
            
        } catch (error) {
            handleError(error, toast)
        } finally {
            loading.value = false
        }
    }

    // Función para obtener category_groups con sus categorías anidadas
    const fetchCategoryGroupsWithCategories = async ({ toast }) => {
        loading.value = true
        
        try {
            const { data: { user } } = await supabase.auth.getUser()
            const userId = user?.id
            
            // **PASO 1:** Obtener todas las categorías primero
            let categoriesQuery = supabase
                .from('categories')
                .select('*')
            
            if (userId) {
                categoriesQuery = categoriesQuery.or(`is_public.eq.true,user_id.eq.${userId}`)
            } else {
                categoriesQuery = categoriesQuery.eq('is_public', true)
            }
            
            const { data: categoriesData, error: categoriesError } = await categoriesQuery
            
            if (categoriesError) {
                handleError(categoriesError, toast)
                return
            }
            
            // **PASO 2:** Obtener todos los grupos de categorías
            let groupsQuery = supabase
                .from('category_groups')
                .select('*')
            
            if (userId) {
                groupsQuery = groupsQuery.or(`is_public.eq.true,user_id.eq.${userId}`)
            } else {
                groupsQuery = groupsQuery.eq('is_public', true)
            }
            
            const { data: groupsData, error: groupsError } = await groupsQuery
            
            if (groupsError) {
                handleError(groupsError, toast)
                return
            }
            
            // **PASO 3:** Ordenar categorías (Privadas primero, luego alfabético)
            const sortedCategories = categoriesData.sort((a, b) => {
                // Primero: Privadas (false) antes que públicas (true)
                if (a.is_public !== b.is_public) {
                    return a.is_public - b.is_public // false (0) < true (1)
                }
                // Segundo: Orden alfabético por nombre (case insensitive)
                return a.name.toLowerCase().localeCompare(b.name.toLowerCase())
            })
            
            // **PASO 4:** Agrupar categorías ordenadas por group_id
            const categoriesByGroup = {}
            sortedCategories.forEach(category => {
                const groupId = category.group_id
                if (!categoriesByGroup[groupId]) {
                    categoriesByGroup[groupId] = []
                }
                categoriesByGroup[groupId].push(category)
            })
            
            // **PASO 5:** Ordenar grupos (Privados primero, luego alfabético)
            const sortedGroups = groupsData.sort((a, b) => {
                // Primero: Privadas (false) antes que públicas (true)
                if (a.is_public !== b.is_public) {
                    return a.is_public - b.is_public // false (0) < true (1)
                }
                // Segundo: Orden alfabético por nombre (case insensitive)
                return a.name.toLowerCase().localeCompare(b.name.toLowerCase())
            })
            
            // **PASO 6:** Agregar categorías ordenadas a cada grupo
            const groupsWithCategories = sortedGroups.map(group => ({
                ...group,
                categories: categoriesByGroup[group.id] || []
            }))
            
            // **PASO 7:** Actualizar estados del store
            categories.value = sortedCategories || []
            categoryGroups.value = groupsWithCategories || []
            
            return groupsWithCategories
        
        } catch (error) {
            handleError(error, toast)
            return []
        } finally {
            loading.value = false
        }
    }

    return {
        // Estados
        categoryGroups,
        categories,
        loading,
        
        // Funciones
        fetchCategoryGroups,
        fetchCategories,
        fetchCategoryGroupsWithCategories  // **NUEVA FUNCIÓN**
    }
})