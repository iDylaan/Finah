import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { supabase } from '@/lib/supabase.js';
import { useSessionStore } from './session';

export const useBankStore = defineStore('banks', () => {
  // ESTADO
  const banks = ref([]);
  const loading = ref(false);
  const loaded = ref(false);
  const error = ref(null);
  const lastFetchTime = ref(null); // Nueva variable para almacenar la última vez que se consultó

  // DEPENDENCIAS
  const sessionStore = useSessionStore();

  // COMPUTED
  const userBanks = computed(() => {
    return banks.value.filter(bank => !bank.es_publico && bank.usuario_id === sessionStore.userId);
  });

  const publicBanks = computed(() => {
    return banks.value.filter(bank => bank.es_publico);
  });

  // ACTIONS
  const fetchBanks = async ({ force = false } = {}) => {
    // Si ya tenemos datos y no es forzado, simplemente regresamos los datos actuales
    if (loaded.value && banks.value.length > 0 && !force) {
      console.log('🔄 Usando datos de bancos en caché');
      return banks.value;
    }
    
    loading.value = true;
    error.value = null;

    try {
      console.log('🔍 Consultando bancos desde la base de datos');
      const { data, error: err } = await supabase
        .from('bancos')
        .select('*')
        .or(`es_publico.eq.true,usuario_id.eq.${sessionStore.userId}`)
        .order('nombre', { ascending: true });

      if (err) throw err;

      banks.value = data || [];
      loaded.value = true;
      lastFetchTime.value = Date.now(); // Guardar timestamp de la última consulta
      
      return banks.value;
    } catch (err) {
      console.error('Error al cargar bancos:', err);
      error.value = err.message || 'Error al cargar bancos';
      return [];
    } finally {
      loading.value = false;
    }
  };

  // La función para refrescar los datos (fuerza una reconsulta)
  const refreshBanks = async () => {
    return await fetchBanks({ force: true });
  };

  const createBank = async (bankData, { toast }) => {
    loading.value = true;

    try {
      const user = sessionStore.user;
      if (!user || !user.id) {
        throw new Error('Usuario no autenticado');
      }

      // Preparar datos para insertar
      const insertData = {
        nombre: bankData.name.trim(),
        biblioteca_iconos: bankData.iconLibrary || 'primevue',
        nombre_icono: bankData.iconName || 'pi pi-building',
        color: bankData.color || '#4B5563', // Color por defecto (gris)
        es_publico: false,
        usuario_id: user.id
      };

      const { data, error: err } = await supabase
        .from('bancos')
        .insert(insertData)
        .select()
        .single();

      if (err) throw err;

      // Agregar a la lista local
      banks.value.push(data);
      

      return data;
    } catch (err) {
      console.error('Error al crear banco:', err);
      
      toast.add({
        severity: 'error',
        summary: 'Error',
        detail: err.message || 'Error al crear el banco',
        life: 3000
      });
      
      return null;
    } finally {
      loading.value = false;
    }
  };

  const updateBank = async (bankId, bankData, { toast }) => {
    loading.value = true;

    try {
      // Verificar si se puede actualizar (no público y propio)
      const bankToUpdate = banks.value.find(bank => bank.id === bankId);
      
      if (!bankToUpdate) {
        throw new Error('Banco no encontrado');
      }
      
      if (bankToUpdate.es_publico) {
        throw new Error('No puedes modificar un banco público del sistema');
      }
      
      if (bankToUpdate.usuario_id !== sessionStore.userId) {
        throw new Error('No tienes permiso para modificar este banco');
      }

      // Preparar datos para actualizar
      const updateData = {
        nombre: bankData.name.trim(),
        biblioteca_iconos: bankData.iconLibrary,
        nombre_icono: bankData.iconName,
        color: bankData.color
      };

      const { data, error: err } = await supabase
        .from('bancos')
        .update(updateData)
        .eq('id', bankId)
        .select()
        .single();

      if (err) throw err;

      // Actualizar en la lista local
      const index = banks.value.findIndex(bank => bank.id === bankId);
      if (index !== -1) {
        banks.value[index] = data;
      }

      return data;
    } catch (err) {
      console.error('Error al actualizar banco:', err);
      
      toast.add({
        severity: 'error',
        summary: 'Error',
        detail: err.message || 'Error al actualizar el banco',
        life: 3000
      });
      
      return null;
    } finally {
      loading.value = false;
    }
  };

  const deleteBank = async (bankId, { toast }) => {
    loading.value = true;

    try {
      // Verificar si se puede eliminar
      const bankToDelete = banks.value.find(bank => bank.id === bankId);
      
      if (!bankToDelete) {
        throw new Error('Banco no encontrado');
      }
      
      if (bankToDelete.es_publico) {
        throw new Error('No puedes eliminar un banco público del sistema');
      }
      
      if (bankToDelete.usuario_id !== sessionStore.userId) {
        throw new Error('No tienes permiso para eliminar este banco');
      }

      const { error: err } = await supabase
        .from('bancos')
        .delete()
        .eq('id', bankId);

      if (err) throw err;

      // Eliminar de la lista local
      banks.value = banks.value.filter(bank => bank.id !== bankId);
      
      toast.add({
        severity: 'success',
        summary: 'Banco eliminado',
        detail: `El banco "${bankToDelete.nombre}" ha sido eliminado correctamente`,
        life: 3000
      });

      return true;
    } catch (err) {
      console.error('Error al eliminar banco:', err);
      
      toast.add({
        severity: 'error',
        summary: 'Error',
        detail: err.message || 'Error al eliminar el banco',
        life: 3000
      });
      
      return false;
    } finally {
      loading.value = false;
    }
  };

  // Añadimos la función para borrar la caché (útil en logout)
  const clearCache = () => {
    banks.value = [];
    loaded.value = false;
    lastFetchTime.value = null;
    error.value = null;
  };

  return {
    // Estado
    banks,
    loading,
    loaded,
    error,
    lastFetchTime,
    
    // Getters
    userBanks,
    publicBanks,
    
    // Acciones
    fetchBanks,
    refreshBanks,
    createBank,
    updateBank,
    deleteBank,
    clearCache
  };
});