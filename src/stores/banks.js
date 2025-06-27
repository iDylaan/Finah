import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { supabase } from '@/lib/supabase.js'; // Corrección: importación directa
import { useSessionStore } from './session';

export const useBankStore = defineStore('banks', () => {
  // ESTADO
  const banks = ref([]);
  const loading = ref(false);
  const loaded = ref(false);
  const error = ref(null);

  // DEPENDENCIAS
  // Eliminada la desestructuración: const { supabase } = useSupabase();
  const sessionStore = useSessionStore();

  // COMPUTED
  const userBanks = computed(() => {
    return banks.value.filter(bank => !bank.is_public && bank.user_id === sessionStore.userId);
  });

  const publicBanks = computed(() => {
    return banks.value.filter(bank => bank.is_public);
  });

  // ACTIONS
  const fetchBanks = async () => {
    loading.value = true;
    error.value = null;

    try {
      const { data, error: err } = await supabase
        .from('banks')
        .select('*')
        .or(`is_public.eq.true,user_id.eq.${sessionStore.userId}`)
        .order('name', { ascending: true });

      if (err) throw err;

      banks.value = data || [];
      loaded.value = true;
    } catch (err) {
      console.error('Error al cargar bancos:', err);
      error.value = err.message || 'Error al cargar bancos';
    } finally {
      loading.value = false;
    }
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
        name: bankData.name.trim(),
        icon_library: bankData.iconLibrary || 'primevue',
        icon_name: bankData.iconName || 'pi pi-building',
        color: bankData.color || '#4B5563', // Color por defecto (gris)
        is_public: false,
        user_id: user.id
      };

      const { data, error: err } = await supabase
        .from('banks')
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
      
      if (bankToUpdate.is_public) {
        throw new Error('No puedes modificar un banco público del sistema');
      }
      
      if (bankToUpdate.user_id !== sessionStore.userId) {
        throw new Error('No tienes permiso para modificar este banco');
      }

      // Preparar datos para actualizar
      const updateData = {
        name: bankData.name.trim(),
        icon_library: bankData.iconLibrary,
        icon_name: bankData.iconName,
        color: bankData.color
      };

      const { data, error: err } = await supabase
        .from('banks')
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
      
      if (bankToDelete.is_public) {
        throw new Error('No puedes eliminar un banco público del sistema');
      }
      
      if (bankToDelete.user_id !== sessionStore.userId) {
        throw new Error('No tienes permiso para eliminar este banco');
      }

      const { error: err } = await supabase
        .from('banks')
        .delete()
        .eq('id', bankId);

      if (err) throw err;

      // Eliminar de la lista local
      banks.value = banks.value.filter(bank => bank.id !== bankId);
      
      toast.add({
        severity: 'success',
        summary: 'Banco eliminado',
        detail: `El banco "${bankToDelete.name}" ha sido eliminado correctamente`,
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

  return {
    // Estado
    banks,
    loading,
    loaded,
    error,
    
    // Getters
    userBanks,
    publicBanks,
    
    // Acciones
    fetchBanks,
    createBank,
    updateBank,
    deleteBank
  };
});