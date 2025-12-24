<template>
    <Dialog
        v-model:visible="visible"
        header="Invitar miembros al grupo"
        :modal="true"
        :closable="true"
        :draggable="false"
        class="w-full max-w-lg"
        @hide="handleClose"
    >
        <div class="space-y-6 py-4">
            <!-- Email -->
            <div class="space-y-2">
                <label for="email" class="block text-sm font-medium text-surface-900 dark:text-surface-0">
                    Correo electrónico <span class="text-red-500">*</span>
                </label>
                <InputText
                    id="email"
                    v-model="formData.email"
                    type="email"
                    class="w-full"
                    placeholder="ejemplo@correo.com"
                    :invalid="v$.email.$error"
                />
                <small v-if="v$.email.$error" class="text-red-500">
                    {{ v$.email.$errors[0].$message }}
                </small>
                <small v-else class="text-surface-500">
                    Se enviará un correo de invitación a esta dirección
                </small>
            </div>

            <!-- Rol -->
            <div class="space-y-2">
                <label for="rol" class="block text-sm font-medium text-surface-900 dark:text-surface-0">
                    Rol en el grupo <span class="text-red-500">*</span>
                </label>
                <Select
                    id="rol"
                    v-model="formData.rol"
                    :options="availableRoles"
                    optionLabel="label"
                    optionValue="value"
                    class="w-full"
                    placeholder="Selecciona un rol"
                >
                    <template #value="slotProps">
                        <div v-if="slotProps.value" class="flex items-center gap-2">
                            <Tag 
                                :value="getRoleLabel(slotProps.value)" 
                                :severity="getRoleSeverity(slotProps.value)"
                            />
                        </div>
                        <span v-else>{{ slotProps.placeholder }}</span>
                    </template>
                    <template #option="slotProps">
                        <div class="flex flex-col">
                            <Tag 
                                :value="slotProps.option.label" 
                                :severity="getRoleSeverity(slotProps.option.value)"
                                class="mb-1"
                            />
                            <small class="text-surface-500">{{ slotProps.option.description }}</small>
                        </div>
                    </template>
                </Select>
            </div>

            <!-- Mensaje opcional -->
            <div class="space-y-2">
                <label for="mensaje" class="block text-sm font-medium text-surface-900 dark:text-surface-0">
                    Mensaje personalizado (opcional)
                </label>
                <Textarea
                    id="mensaje"
                    v-model="formData.mensaje"
                    class="w-full"
                    rows="4"
                    placeholder="Escribe un mensaje para acompañar la invitación..."
                    :maxlength="500"
                />
                <small class="text-surface-500">
                    {{ formData.mensaje?.length || 0 }} / 500 caracteres
                </small>
            </div>

            <!-- Info -->
            <Message severity="info" :closable="false">
                <div class="flex items-start gap-2">
                    <i class="pi pi-info-circle"></i>
                    <div class="flex-1 text-sm">
                        <p class="font-medium mb-1">¿Cómo funciona?</p>
                        <ul class="list-disc list-inside space-y-1 text-surface-700 dark:text-surface-300">
                            <li>Se enviará un correo al destinatario</li>
                            <li>Debe tener cuenta en Finheal para aceptar</li>
                            <li>La invitación caduca en 7 días</li>
                        </ul>
                    </div>
                </div>
            </Message>
        </div>

        <!-- Footer -->
        <template #footer>
            <Button 
                label="Cancelar" 
                icon="pi pi-times" 
                @click="handleClose" 
                severity="secondary" 
                outlined
            />
            <Button 
                label="Enviar invitación" 
                icon="pi pi-send" 
                @click="handleSubmit" 
                :loading="loading"
            />
        </template>
    </Dialog>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useToast } from 'primevue/usetoast'
import { useVuelidate } from '@vuelidate/core'
import { required, email } from '@vuelidate/validators'
import { useGroupsStore } from '@/stores/groups'

// Props
const props = defineProps({
    visible: {
        type: Boolean,
        default: false
    },
    groupId: {
        type: String,
        required: true
    }
})

// Emits
const emit = defineEmits(['update:visible', 'invited'])

// Composables
const toast = useToast()
const groupsStore = useGroupsStore()

// Estados
const loading = ref(false)
const formData = ref({
    email: '',
    rol: 'miembro',
    mensaje: ''
})

// Computed
const visible = computed({
    get: () => props.visible,
    set: (value) => emit('update:visible', value)
})

const availableRoles = [
    { 
        label: 'Miembro', 
        value: 'miembro',
        description: 'Puede ver y registrar gastos del grupo'
    },
    { 
        label: 'Administrador', 
        value: 'administrador',
        description: 'Puede gestionar miembros y configuración'
    }
]

// Validaciones
const rules = {
    email: {
        required: {
            $message: 'El correo electrónico es obligatorio'
        },
        email: {
            $message: 'Debe ser un correo electrónico válido'
        }
    }
}

const v$ = useVuelidate(rules, formData)

// Métodos
const resetForm = () => {
    formData.value = {
        email: '',
        rol: 'miembro',
        mensaje: ''
    }
    v$.value.$reset()
}

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
        await groupsStore.createInvitation(props.groupId, {
            email_invitado: formData.value.email,
            rol_asignado: formData.value.rol,
            mensaje: formData.value.mensaje || null
        }, { toast })

        toast.add({
            severity: 'success',
            summary: 'Invitación enviada',
            detail: `Se ha enviado la invitación a ${formData.value.email}`,
            life: 3000
        })

        emit('invited')
        handleClose()
    } catch (error) {
        console.error('Error al enviar invitación:', error)
        toast.add({
            severity: 'error',
            summary: 'Error',
            detail: error.message || 'No se pudo enviar la invitación',
            life: 5000
        })
    } finally {
        loading.value = false
    }
}

const getRoleLabel = (role) => {
    const labels = {
        'administrador': 'Administrador',
        'miembro': 'Miembro'
    }
    return labels[role] || role
}

const getRoleSeverity = (role) => {
    const severities = {
        'administrador': 'warning',
        'miembro': 'info'
    }
    return severities[role] || 'secondary'
}
</script>

<style scoped>
.space-y-6 > * + * {
    margin-top: 1.5rem;
}

.space-y-2 > * + * {
    margin-top: 0.5rem;
}
</style>
