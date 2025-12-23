<template>
    <Dialog v-model:visible="visible" :header="isEditing ? 'Editar Grupo' : 'Nuevo Grupo'" :modal="true"
        :closable="true" :draggable="false" class="w-full max-w-2xl" @hide="handleClose">
        <div class="space-y-6 py-4">
            <!-- Nombre -->
            <div class="space-y-2">
                <label for="nombre" class="block text-sm font-medium text-surface-900 dark:text-surface-0">
                    Nombre del grupo <span class="text-red-500">*</span>
                </label>
                <InputText id="nombre" v-model="formData.nombre" class="w-full" placeholder="Ej: Familia García"
                    :invalid="v$.nombre.$error" />
                <small v-if="v$.nombre.$error" class="text-red-500">
                    {{ v$.nombre.$errors[0].$message }}
                </small>
            </div>

            <!-- Descripción -->
            <div class="space-y-2">
                <label for="descripcion" class="block text-sm font-medium text-surface-900 dark:text-surface-0">
                    Descripción
                </label>
                <Textarea id="descripcion" v-model="formData.descripcion" class="w-full" rows="3"
                    placeholder="Describe el propósito de este grupo..." />
            </div>

            <!-- Color e Icono -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <!-- Color -->
                <div class="space-y-2">
                    <label class="block text-sm font-medium text-surface-900 dark:text-surface-0">
                        Color
                    </label>
                    <CustomColorPicker v-model="formData.color" :colors="suggestedColors" />
                </div>

                <!-- Icono -->
                <div class="space-y-2">
                    <label class="block text-sm font-medium text-surface-900 dark:text-surface-0">
                        Icono
                    </label>
                    <IconPicker v-model="formData.icon" :suggested-icons="suggestedIcons" />
                </div>
            </div>

            <!-- Límite de miembros -->
            <div class="space-y-2">
                <label for="limite_miembros" class="block text-sm font-medium text-surface-900 dark:text-surface-0">
                    Límite de miembros
                </label>
                <InputNumber v-model="formData.limite_miembros" placeholder="Sin límite" id="limite_miembros"
                    inputId="horizontal-buttons" :min="2" :max="50" showButtons buttonLayout="horizontal" :step="1"
                    fluid>
                    <template #incrementicon>
                        <span class="pi pi-plus" />
                    </template>
                    <template #decrementicon>
                        <span class="pi pi-minus" />
                    </template>
                </InputNumber>
                <small class="text-surface-500">
                    Número máximo de miembros permitidos en el grupo (opcional)
                </small>
            </div>

            <!-- Vista previa -->
            <div
                class="p-4 rounded-lg bg-surface-50 dark:bg-surface-900 border border-surface-200 dark:border-surface-700">
                <p class="text-sm font-medium text-surface-700 dark:text-surface-300 mb-3">Vista previa</p>
                <div class="h-24 rounded-lg flex items-center justify-center mb-3"
                    :style="{ backgroundColor: formData.color || '#3B82F6' }">
                    <i :class="[formData.icon || 'pi-users', 'text-5xl text-white']"></i>
                </div>
                <h4 class="font-semibold text-surface-900 dark:text-surface-0 mb-1">
                    {{ formData.nombre || 'Nombre del grupo' }}
                </h4>
                <p class="text-sm text-surface-600 dark:text-surface-400">
                    {{ formData.descripcion || 'Descripción del grupo' }}
                </p>
            </div>
        </div>

        <!-- Footer -->
        <template #footer>
            <Button label="Cancelar" icon="pi pi-times" @click="handleClose" severity="secondary" outlined />
            <Button :label="isEditing ? 'Guardar cambios' : 'Crear grupo'" icon="pi pi-check" @click="handleSubmit"
                :loading="loading" />
        </template>
    </Dialog>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useToast } from 'primevue/usetoast'
import { useVuelidate } from '@vuelidate/core'
import { required, minLength, maxLength } from '@vuelidate/validators'
import { useGroupsStore } from '@/stores/groups'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import Textarea from 'primevue/textarea'
import InputNumber from 'primevue/inputnumber'
import Button from 'primevue/button'
import CustomColorPicker from '@/components/CustomColorPicker.vue'
import IconPicker from '@/components/IconPicker.vue'

// Props
const props = defineProps({
    visible: {
        type: Boolean,
        default: false
    },
    group: {
        type: Object,
        default: null
    }
})

// Emits
const emit = defineEmits(['update:visible', 'saved'])

// Composables
const toast = useToast()
const groupsStore = useGroupsStore()

// Estados
const loading = ref(false)
const formData = ref({
    nombre: '',
    descripcion: '',
    color: '#3B82F6',
    icon: 'groups',
    limite_miembros: null
})

// Computed
const isEditing = computed(() => !!props.group?.id)

const visible = computed({
    get: () => props.visible,
    set: (value) => emit('update:visible', value)
})

// Colores sugeridos
const suggestedColors = [
    '#3B82F6', // blue
    '#10B981', // green
    '#F59E0B', // amber
    '#EF4444', // red
    '#8B5CF6', // violet
    '#EC4899', // pink
    '#14B8A6', // teal
    '#F97316', // orange
]

// Iconos sugeridos
const suggestedIcons = [
    'pi-users',
    'pi-home',
    'pi-heart',
    'pi-briefcase',
    'pi-graduation-cap',
    'pi-car',
    'pi-shopping-bag',
    'pi-globe',
]

// Validaciones
const rules = {
    nombre: {
        required: {
            $message: 'El nombre es obligatorio'
        },
        minLength: minLength(2),
        maxLength: maxLength(100)
    }
}

const v$ = useVuelidate(rules, formData)

// Métodos
const resetForm = () => {
    formData.value = {
        nombre: '',
        descripcion: '',
        color: '#3B82F6',
        icon: 'groups',
        limite_miembros: null
    }
    v$.value.$reset()
}

// Watch para inicializar el formulario cuando se pasa un grupo
watch(() => props.group, (newGroup) => {
    if (newGroup) {
        formData.value = {
            nombre: newGroup.nombre || '',
            descripcion: newGroup.descripcion || '',
            color: newGroup.color || '#3B82F6',
            icon: newGroup.icon || 'groups',
            limite_miembros: newGroup.limite_miembros
        }
    } else {
        resetForm()
    }
}, { immediate: true })

const handleClose = () => {
    resetForm()
    visible.value = false
}

const handleSubmit = async () => {
    // Validar formulario
    const isValid = await v$.value.$validate()
    if (!isValid) {
        return
    }

    loading.value = true

    try {
        if (isEditing.value) {
            await groupsStore.updateGroup(props.group.id, formData.value, { toast })
            toast.add({
                severity: 'success',
                summary: 'Grupo actualizado',
                detail: 'El grupo se ha actualizado correctamente',
                life: 3000
            })
        } else {
            await groupsStore.createGroup(formData.value, { toast })
            toast.add({
                severity: 'success',
                summary: 'Grupo creado',
                detail: 'El grupo se ha creado correctamente',
                life: 3000
            })
        }

        emit('saved')
        handleClose()
    } catch (error) {
        console.error('Error al guardar grupo:', error)
        toast.add({
            severity: 'error',
            summary: 'Error',
            detail: error.message || 'No se pudo guardar el grupo',
            life: 5000
        })
    } finally {
        loading.value = false
    }
}
</script>

<style scoped>
.space-y-2>*+* {
    margin-top: 0.5rem;
}

.space-y-6>*+* {
    margin-top: 1.5rem;
}
</style>
