# 📋 LISTA DE REQUERIMIENTOS - FINHEAL

## 🎯 Objetivo General
Desarrollar una aplicación de gestión financiera personal y grupal con capacidades de:
- Registro de ingresos y gastos
- Gestión de cuentas (efectivo, débito, crédito)
- Grupos financieros compartidos
- Metas de ahorro y presupuestos
- Estadísticas y análisis financiero
- Notificaciones inteligentes

---

## 📊 FASE 1: FUNDAMENTOS DE TRANSACCIONES

### RN001 - Store de Transacciones (Pinia)
**Prioridad:** CRÍTICA  
**Dependencias:** Ninguna  
**Descripción:** Crear el store de Pinia para gestionar transacciones  
**Tareas:**
- [ ] Crear archivo `src/stores/transactions.js`
- [ ] Implementar estado: `transactions`, `loading`, `error`
- [ ] Función: `fetchTransactions()` - Obtener transacciones del usuario
- [ ] Función: `createTransaction()` - Crear nueva transacción
- [ ] Función: `updateTransaction()` - Actualizar transacción existente
- [ ] Función: `deleteTransaction()` - Eliminar transacción
- [ ] Sistema de caché similar al de accounts.js
- [ ] Gestión de fechas con filtros (mes actual, rango personalizado)

**Criterios de aceptación:**
- ✅ El store debe cachear las transacciones
- ✅ Debe actualizar automáticamente el saldo de la cuenta al crear/eliminar transacción
- ✅ Debe soportar los 5 tipos de transacción (gasto, ingreso, transferencia, pago_deuda, pago_credito)

---

### RN002 - Componente de Formulario de Transacción
**Prioridad:** CRÍTICA  
**Dependencias:** RN001  
**Descripción:** Formulario para registrar ingresos, gastos y transferencias  
**Tareas:**
- [ ] Crear `src/views/modules/Transactions/components/TransactionForm.vue`
- [ ] SelectButton para tipo de transacción (Gasto/Ingreso/Transferencia)
- [ ] Selector de cuenta de origen
- [ ] Selector de cuenta destino (solo para transferencias)
- [ ] Selector de categoría (filtrado por tipo)
- [ ] Selector de nivel (opcional)
- [ ] Input de monto (usando BalanceInput)
- [ ] DatePicker para fecha de ocurrencia
- [ ] Input de descripción
- [ ] Upload de comprobante (Supabase Storage)
- [ ] Validaciones con Vuelidate

**Criterios de aceptación:**
- ✅ El formulario debe validar que el tipo de cuenta sea compatible con el tipo de transacción
- ✅ Para crédito: gasto RESTA del crédito disponible, pago SUMA al crédito disponible
- ✅ Para débito/efectivo: gasto RESTA, ingreso SUMA
- ✅ Las transferencias deben actualizar ambas cuentas

---

### RN003 - Modal de Transacción Responsive
**Prioridad:** ALTA  
**Dependencias:** RN002  
**Descripción:** Modal que contiene el formulario de transacción  
**Tareas:**
- [ ] Crear `src/views/modules/Transactions/components/TransactionModal.vue`
- [ ] Implementar lógica similar a AccountModal (mobile = full screen)
- [ ] Botón flotante para abrir modal
- [ ] Modo creación y edición
- [ ] Confirmación antes de eliminar

**Criterios de aceptación:**
- ✅ Debe ser full-screen en móvil
- ✅ Debe centrado en desktop
- ✅ Debe cerrar automáticamente después de guardar

---

### RN004 - Vista Principal de Transacciones
**Prioridad:** ALTA  
**Dependencias:** RN001, RN002, RN003  
**Descripción:** Página principal con lista de transacciones  
**Tareas:**
- [ ] Crear `src/views/modules/Transactions/index.vue`
- [ ] Usar PageLayout con header personalizado
- [ ] Lista de transacciones agrupadas por fecha
- [ ] Mostrar: icono de categoría, descripción, monto, cuenta
- [ ] Filtros: por tipo, por cuenta, por categoría, por rango de fechas
- [ ] Búsqueda por descripción
- [ ] Click en transacción para editar
- [ ] Swipe para eliminar (móvil)
- [ ] Balance total del período seleccionado

**Criterios de aceptación:**
- ✅ Debe mostrar ingresos en verde y gastos en rojo
- ✅ Debe agrupar por día (Hoy, Ayer, esta semana, mes anterior)
- ✅ Debe tener scroll infinito o paginación

---

### RN005 - Actualización Automática de Saldos
**Prioridad:** CRÍTICA  
**Dependencias:** RN001, RN002  
**Descripción:** Sistema para actualizar saldos de cuentas al crear/editar/eliminar transacciones  
**Tareas:**
- [ ] Función en store de transactions: `updateAccountBalance()`
- [ ] Trigger en `createTransaction()` para actualizar saldo
- [ ] Trigger en `updateTransaction()` para ajustar saldo (revertir anterior y aplicar nuevo)
- [ ] Trigger en `deleteTransaction()` para revertir saldo
- [ ] Para tarjetas de crédito: actualizar `credito_disponible`
- [ ] Validar que no se exceda el límite de crédito
- [ ] Validar que no haya saldo negativo en efectivo/débito (opcional, con configuración)

**Criterios de aceptación:**
- ✅ Al crear un gasto de $500 en efectivo, el saldo debe reducirse $500
- ✅ Al crear un ingreso de $1000 en débito, el saldo debe aumentar $1000
- ✅ Al crear un gasto de $200 en crédito, credito_disponible debe reducirse $200
- ✅ Al hacer pago de $500 a tarjeta de crédito, credito_disponible debe aumentar $500

---

## 👥 FASE 2: GRUPOS FINANCIEROS

### RN006 - Store de Grupos (Pinia)
**Prioridad:** ALTA  
**Dependencias:** Ninguna  
**Descripción:** Store para gestión de grupos de usuarios  
**Tareas:**
- [ ] Crear `src/stores/groups.js`
- [ ] Estado: `groups`, `currentGroup`, `members`, `loading`
- [ ] Función: `fetchUserGroups()` - Grupos donde el usuario es miembro
- [ ] Función: `createGroup()` - Crear nuevo grupo
- [ ] Función: `updateGroup()` - Actualizar información del grupo
- [ ] Función: `deleteGroup()` - Eliminar grupo (solo owner)
- [ ] Función: `fetchGroupMembers()` - Obtener miembros del grupo
- [ ] Función: `addMember()` - Agregar miembro manualmente
- [ ] Función: `updateMemberRole()` - Cambiar rol de miembro
- [ ] Función: `removeMember()` - Expulsar miembro del grupo
- [ ] Función: `leaveGroup()` - Salir del grupo (si no eres owner)

**Criterios de aceptación:**
- ✅ Solo el owner puede eliminar el grupo
- ✅ Los admins pueden agregar/remover miembros
- ✅ Los miembros normales solo pueden ver información

---

### RN007 - Store de Invitaciones
**Prioridad:** ALTA  
**Dependencias:** RN006  
**Descripción:** Store para gestión de invitaciones a grupos  
**Tareas:**
- [ ] Crear `src/stores/invitations.js`
- [ ] Estado: `sentInvitations`, `receivedInvitations`, `loading`
- [ ] Función: `fetchSentInvitations()` - Invitaciones enviadas por el usuario
- [ ] Función: `fetchReceivedInvitations()` - Invitaciones recibidas (por email)
- [ ] Función: `createInvitation()` - Enviar invitación a un email
- [ ] Función: `acceptInvitation()` - Aceptar invitación usando RPC
- [ ] Función: `rejectInvitation()` - Rechazar invitación
- [ ] Función: `cancelInvitation()` - Cancelar invitación enviada
- [ ] Función: `resendInvitation()` - Reenviar invitación expirada

**Criterios de aceptación:**
- ✅ Las invitaciones deben expirar después de 7 días
- ✅ Debe generar un token único por invitación
- ✅ Al aceptar, debe agregar al usuario como miembro del grupo

---

### RN008 - Vista de Gestión de Grupos
**Prioridad:** ALTA  
**Dependencias:** RN006, RN007  
**Descripción:** Página para administrar grupos financieros  
**Tareas:**
- [ ] Crear `src/views/modules/Groups/index.vue`
- [ ] Lista de grupos del usuario
- [ ] Card por cada grupo mostrando: nombre, miembros, rol
- [ ] Botón para crear nuevo grupo
- [ ] Click en grupo para ver detalles
- [ ] Indicador visual del rol (Owner/Admin/Miembro)

**Criterios de aceptación:**
- ✅ Debe mostrar grupos ordenados por fecha de creación
- ✅ Debe mostrar cantidad de miembros
- ✅ Debe permitir filtrar por rol

---

### RN009 - Componente de Detalles de Grupo
**Prioridad:** ALTA  
**Dependencias:** RN006, RN007  
**Descripción:** Vista detallada de un grupo específico  
**Tareas:**
- [ ] Crear `src/views/modules/Groups/components/GroupDetails.vue`
- [ ] Información general: nombre, descripción, fecha creación
- [ ] Lista de miembros con avatares y roles
- [ ] Porcentaje de participación de cada miembro
- [ ] Botón para invitar nuevos miembros
- [ ] Botón para editar información (solo owner/admin)
- [ ] Botón para abandonar grupo
- [ ] Botón para eliminar grupo (solo owner)
- [ ] Lista de invitaciones pendientes

**Criterios de aceptación:**
- ✅ Los miembros deben estar ordenados por rol (owner → admin → miembro)
- ✅ Debe mostrar la suma total de porcentajes de participación (debe ser 100%)

---

### RN010 - Modal de Invitación a Grupo
**Prioridad:** MEDIA  
**Dependencias:** RN007  
**Descripción:** Formulario para invitar usuarios al grupo  
**Tareas:**
- [ ] Crear `src/views/modules/Groups/components/InvitationModal.vue`
- [ ] Input de email del invitado
- [ ] Selector de rol (Miembro/Admin)
- [ ] Input numérico para porcentaje de participación
- [ ] TextArea para mensaje personalizado
- [ ] Validación de email
- [ ] Mostrar link de invitación generado
- [ ] Botón para copiar link

**Criterios de aceptación:**
- ✅ Debe validar que el email no sea de un miembro existente
- ✅ Debe validar que el porcentaje sea entre 0 y 100
- ✅ El link debe incluir el token único

---

### RN011 - Página Pública de Aceptación de Invitación
**Prioridad:** MEDIA  
**Dependencias:** RN007  
**Descripción:** Página pública para que usuarios acepten invitaciones  
**Tareas:**
- [ ] Crear `src/views/pages/AcceptInvitation.vue`
- [ ] Ruta pública: `/invitations/:token`
- [ ] Validar token al cargar la página
- [ ] Mostrar información del grupo
- [ ] Mostrar quien invitó
- [ ] Botón para aceptar (si está autenticado)
- [ ] Botón para rechazar
- [ ] Redirección a login si no está autenticado
- [ ] Manejo de invitaciones expiradas

**Criterios de aceptación:**
- ✅ Si el usuario no está autenticado, debe redirigir a login con return URL
- ✅ Si la invitación está expirada, debe mostrar mensaje claro
- ✅ Después de aceptar, debe redirigir a la página del grupo

---

## 💰 FASE 3: DIVISIÓN DE GASTOS GRUPALES

### RN012 - Función para Dividir Gastos Automáticamente
**Prioridad:** ALTA  
**Dependencias:** RN001, RN006  
**Descripción:** Implementar lógica para dividir gastos entre miembros del grupo  
**Tareas:**
- [ ] Modificar `createTransaction()` en store de transactions
- [ ] Agregar checkbox "Dividir entre grupo" en TransactionForm
- [ ] Selector de grupo (si la cuenta es grupal)
- [ ] Llamar a RPC `dividir_gasto_grupal()` después de crear transacción
- [ ] Mostrar preview de cómo se dividirá antes de confirmar
- [ ] Store de divisiones para consultar gastos divididos

**Criterios de aceptación:**
- ✅ Debe dividir según los porcentajes de participación de cada miembro
- ✅ La suma de las divisiones debe ser igual al monto total
- ✅ Debe crear registros en `divisiones_transaccion`

---

### RN013 - Vista de Gastos Compartidos
**Prioridad:** MEDIA  
**Dependencias:** RN012  
**Descripción:** Página para ver gastos compartidos del grupo  
**Tareas:**
- [ ] Crear `src/views/modules/Groups/components/SharedExpenses.vue`
- [ ] Lista de transacciones divididas del grupo
- [ ] Mostrar por cada gasto: descripción, total, divisiones por persona
- [ ] Filtros por período
- [ ] Resumen: total gastado, mi parte, diferencia con otros
- [ ] Gráfica de distribución de gastos por miembro

**Criterios de aceptación:**
- ✅ Debe mostrar claramente cuánto debe cada persona
- ✅ Debe tener opción de exportar a PDF
- ✅ Debe calcular "quién le debe a quién"

---

### RN014 - Sistema de Saldos Entre Miembros
**Prioridad:** MEDIA  
**Dependencias:** RN013  
**Descripción:** Calcular y mostrar deudas entre miembros del grupo  
**Tareas:**
- [ ] Función: `calculateMemberBalances()` - Calcular saldos entre miembros
- [ ] Algoritmo para simplificar deudas (A debe a B, B debe a C → A debe a C)
- [ ] Vista de saldos con indicadores visuales
- [ ] Botón "Marcar como pagado" para liquidar deudas

**Criterios de aceptación:**
- ✅ Debe mostrar "Juan debe $500 a María"
- ✅ Debe simplificar las deudas al mínimo número de transacciones
- ✅ Debe permitir registrar pagos entre miembros

---

## 🎯 FASE 4: METAS Y PRESUPUESTOS

### RN015 - Store de Metas (Pinia)
**Prioridad:** ALTA  
**Dependencias:** Ninguna  
**Descripción:** Store para gestión de metas financieras  
**Tareas:**
- [ ] Crear `src/stores/goals.js`
- [ ] Estado: `goals`, `loading`, `error`
- [ ] Función: `fetchGoals()` - Obtener metas del usuario
- [ ] Función: `createGoal()` - Crear nueva meta
- [ ] Función: `updateGoal()` - Actualizar meta
- [ ] Función: `deleteGoal()` - Eliminar meta
- [ ] Función: `updateProgress()` - Actualizar monto actual
- [ ] Función: `completeGoal()` - Marcar como completada
- [ ] Usar vista RPC `obtener_progreso_metas()`

**Criterios de aceptación:**
- ✅ Debe soportar 3 tipos de metas (ahorro, compra, presupuesto)
- ✅ Debe calcular automáticamente el porcentaje de progreso
- ✅ Debe detectar metas vencidas

---

### RN016 - Componente de Formulario de Meta
**Prioridad:** ALTA  
**Dependencias:** RN015  
**Descripción:** Formulario para crear/editar metas  
**Tareas:**
- [ ] Crear `src/views/modules/Goals/components/GoalForm.vue`
- [ ] SelectButton para tipo (Ahorro/Compra/Presupuesto)
- [ ] Input de título
- [ ] Input de monto objetivo (BalanceInput)
- [ ] DatePicker de fecha inicio y fin
- [ ] Selector de categoría (para presupuestos)
- [ ] Selector de periodicidad
- [ ] Input de monto por período (para ahorros recurrentes)
- [ ] IconPicker para seleccionar icono
- [ ] ColorPicker para color personalizado
- [ ] Slider para porcentaje de notificación (50-100%)
- [ ] Checkbox "Permitir exceder" (para presupuestos flexibles)
- [ ] Selector de grupo (para metas compartidas)

**Criterios de aceptación:**
- ✅ Para presupuestos, debe requerir categoría
- ✅ Para ahorros recurrentes, debe calcular cuánto ahorrar por período
- ✅ Debe validar que fecha fin sea posterior a fecha inicio

---

### RN017 - Vista Principal de Metas
**Prioridad:** ALTA  
**Dependencias:** RN015, RN016  
**Descripción:** Página con lista de metas  
**Tareas:**
- [ ] Crear `src/views/modules/Goals/index.vue`
- [ ] Cards de metas con barra de progreso
- [ ] Agrupación por tipo (Ahorros/Compras/Presupuestos)
- [ ] Indicadores visuales de estado (en progreso, cerca del objetivo, completada, vencida)
- [ ] Click para ver detalles y editar
- [ ] Botón de acción rápida para agregar dinero a la meta
- [ ] Resumen: total de metas, monto objetivo total, progreso general

**Criterios de aceptación:**
- ✅ Debe mostrar progreso con barra visual y porcentaje
- ✅ Debe resaltar metas cerca del objetivo (>80%)
- ✅ Debe mostrar días restantes para metas con fecha límite

---

### RN018 - Modal de Detalles de Meta
**Prioridad:** MEDIA  
**Dependencias:** RN015, RN016  
**Descripción:** Vista detallada de una meta específica  
**Tareas:**
- [ ] Crear `src/views/modules/Goals/components/GoalDetails.vue`
- [ ] Gráfica de progreso (línea temporal)
- [ ] Historial de aportes
- [ ] Proyección para alcanzar la meta
- [ ] Botón para agregar aporte
- [ ] Botón para retirar dinero (disminuir progreso)
- [ ] Botón para editar meta
- [ ] Botón para eliminar meta
- [ ] Para metas grupales: mostrar aporte por miembro

**Criterios de aceptación:**
- ✅ Debe mostrar gráfica de crecimiento del ahorro
- ✅ Debe calcular fecha estimada de completación basado en tendencia
- ✅ Para metas grupales, debe mostrar quién ha aportado cuánto

---

### RN019 - Sistema de Notificaciones para Metas
**Prioridad:** MEDIA  
**Dependencias:** RN015  
**Descripción:** Notificar cuando se alcance cierto porcentaje de la meta  
**Tareas:**
- [ ] Función: `checkGoalNotifications()` - Verificar si una meta debe notificar
- [ ] Crear notificación cuando se alcance el `notificar_al_alcanzar`
- [ ] Crear notificación cuando se complete la meta
- [ ] Crear notificación cuando se venza una meta sin completar
- [ ] Crear notificación cuando un presupuesto llegue al límite
- [ ] Store de notificaciones

**Criterios de aceptación:**
- ✅ Debe notificar solo UNA VEZ cuando se alcance el porcentaje
- ✅ Las notificaciones deben aparecer en la UI (badge, campana)
- ✅ Debe poder marcar notificaciones como leídas

---

### RN020 - Validación de Presupuestos al Crear Gasto
**Prioridad:** MEDIA  
**Dependencias:** RN015, RN001  
**Descripción:** Validar que no se exceda el presupuesto al crear gasto  
**Tareas:**
- [ ] Modificar `createTransaction()` para validar presupuestos
- [ ] Obtener presupuesto activo de la categoría
- [ ] Sumar gastos del período actual
- [ ] Si `permitir_exceder = false`, bloquear transacción si excede
- [ ] Si `permitir_exceder = true`, mostrar advertencia pero permitir
- [ ] Mostrar modal informativo con el estado del presupuesto

**Criterios de aceptación:**
- ✅ Debe validar solo si existe un presupuesto activo para esa categoría
- ✅ Debe mostrar cuánto queda disponible del presupuesto
- ✅ Debe respetar la configuración `permitir_exceder`

---

## 📊 FASE 5: ESTADÍSTICAS Y ANÁLISIS

### RN021 - Dashboard Principal
**Prioridad:** ALTA  
**Dependencias:** RN001, RN015  
**Descripción:** Página de inicio con resumen financiero  
**Tareas:**
- [ ] Crear/actualizar `src/views/Dashboard.vue`
- [ ] Widget de balance total (usar vista `vista_patrimonio_usuario`)
- [ ] Widget de ingresos vs gastos del mes
- [ ] Widget de top 5 categorías con más gastos
- [ ] Widget de próximos pagos (tarjetas de crédito, cuotas MSI)
- [ ] Widget de progreso de metas principales
- [ ] Widget de notificaciones recientes
- [ ] Gráfica de tendencia mensual (últimos 6 meses)

**Criterios de aceptación:**
- ✅ Debe cargar rápido (usar vistas materializadas)
- ✅ Debe ser responsive
- ✅ Debe tener opción de seleccionar período (mes/trimestre/año)

---

### RN022 - Vista de Estadísticas Detalladas
**Prioridad:** MEDIA  
**Dependencias:** RN001, RN021  
**Descripción:** Página con análisis financiero profundo  
**Tareas:**
- [ ] Crear `src/views/modules/Analytics/index.vue`
- [ ] Gráfica de pastel: gastos por categoría
- [ ] Gráfica de barras: gastos por mes (comparativa)
- [ ] Gráfica de línea: evolución del patrimonio
- [ ] Tabla de top gastos individuales
- [ ] Análisis de tendencias (gastas más los fines de semana, etc.)
- [ ] Comparativa año anterior
- [ ] Exportar reportes a PDF

**Criterios de aceptación:**
- ✅ Debe usar Chart.js o similar
- ✅ Debe permitir filtrar por rango de fechas
- ✅ Debe mostrar insights automáticos (ej: "Gastaste 20% más este mes")

---

### RN023 - Gráfica de Evolución de Patrimonio
**Prioridad:** MEDIA  
**Dependencias:** RN021  
**Descripción:** Gráfica histórica del patrimonio neto  
**Tareas:**
- [ ] Usar tabla `historial_saldos`
- [ ] Gráfica de línea mostrando patrimonio por día/semana/mes
- [ ] Opción de ver por cuenta individual o total
- [ ] Marcadores de eventos importantes (grandes ingresos/gastos)
- [ ] Proyección lineal del crecimiento

**Criterios de aceptación:**
- ✅ Debe usar datos reales del historial de saldos
- ✅ Debe tener zoom y pan
- ✅ Debe mostrar tooltips informativos

---

### RN024 - Reportes Exportables
**Prioridad:** BAJA  
**Dependencias:** RN022  
**Descripción:** Generar reportes en PDF/Excel  
**Tareas:**
- [ ] Función: `generateReport()` - Generar reporte financiero
- [ ] Selección de período
- [ ] Selección de tipo (resumen/detallado)
- [ ] Opción de incluir gráficas
- [ ] Generación de PDF con jsPDF
- [ ] Generación de Excel con xlsx
- [ ] Envío por email (opcional)

**Criterios de aceptación:**
- ✅ El PDF debe tener buen formato y ser legible
- ✅ Debe incluir logo y datos del usuario
- ✅ Debe tener fecha de generación

---

## 💳 FASE 6: GESTIÓN AVANZADA DE CRÉDITO

### RN025 - Calculadora de Compras MSI
**Prioridad:** MEDIA  
**Dependencias:** RN001  
**Descripción:** Herramienta para calcular y registrar compras a meses sin intereses  
**Tareas:**
- [ ] Crear `src/views/modules/CreditCards/components/MSICalculator.vue`
- [ ] Input de monto total de la compra
- [ ] Selector de meses (3, 6, 9, 12, 18, 24)
- [ ] Mostrar monto de cuota mensual
- [ ] Selector de tarjeta de crédito
- [ ] DatePicker de fecha de compra
- [ ] Generar calendario de pagos
- [ ] Botón para registrar la compra MSI

**Criterios de aceptación:**
- ✅ Debe crear registro en `compras_msi`
- ✅ Debe crear registros en `compras_deuda` y `cuotas_deuda`
- ✅ Debe actualizar el crédito disponible de la tarjeta

---

### RN026 - Vista de Gestión de MSI
**Prioridad:** MEDIA  
**Dependencias:** RN025  
**Descripción:** Página para ver y gestionar compras MSI activas  
**Tareas:**
- [ ] Crear `src/views/modules/CreditCards/components/MSIManagement.vue`
- [ ] Lista de compras MSI activas
- [ ] Mostrar por cada MSI: descripción, monto total, cuotas pagadas/restantes, próxima cuota
- [ ] Opción de marcar cuota como pagada
- [ ] Alerta de cuotas próximas a vencer
- [ ] Resumen: total en MSI activos, próximo pago

**Criterios de aceptación:**
- ✅ Debe mostrar claramente cuántas cuotas faltan
- ✅ Debe calcular el total comprometido en MSI
- ✅ Debe permitir pagar cuotas adelantadas

---

### RN027 - Recordatorios de Pago de Tarjetas
**Prioridad:** MEDIA  
**Dependencias:** RN019  
**Descripción:** Sistema de notificaciones para fechas de pago  
**Tareas:**
- [ ] Función: `checkCreditCardPayments()` - Verificar fechas de pago
- [ ] Notificación 3 días antes de la fecha de pago
- [ ] Notificación el día de pago
- [ ] Notificación si se pasó la fecha de pago
- [ ] Calcular pago mínimo y pago para no generar intereses
- [ ] Sugerencia de pago basado en saldo disponible

**Criterios de aceptación:**
- ✅ Debe notificar cada mes automáticamente
- ✅ Debe mostrar el monto exacto a pagar
- ✅ Debe tener botón de acción rápida para registrar el pago

---

## 🔔 FASE 7: SISTEMA DE NOTIFICACIONES

### RN028 - Store de Notificaciones
**Prioridad:** MEDIA  
**Dependencias:** RN019  
**Descripción:** Store para gestión de notificaciones  
**Tareas:**
- [ ] Crear `src/stores/notifications.js`
- [ ] Estado: `notifications`, `unreadCount`, `loading`
- [ ] Función: `fetchNotifications()` - Obtener notificaciones del usuario
- [ ] Función: `markAsRead()` - Marcar como leída
- [ ] Función: `markAllAsRead()` - Marcar todas como leídas
- [ ] Función: `deleteNotification()` - Eliminar notificación
- [ ] Polling cada 60 segundos para nuevas notificaciones

**Criterios de aceptación:**
- ✅ Debe mostrar badge con cantidad de no leídas
- ✅ Debe ordenar por fecha (más recientes primero)
- ✅ Debe agrupar por tipo

---

### RN029 - Componente de Centro de Notificaciones
**Prioridad:** MEDIA  
**Dependencias:** RN028  
**Descripción:** Dropdown/Panel con lista de notificaciones  
**Tareas:**
- [ ] Crear `src/components/NotificationCenter.vue`
- [ ] Botón de campana en AppTopbar
- [ ] Badge con contador de no leídas
- [ ] Dropdown con lista de notificaciones
- [ ] Iconos diferentes por tipo de notificación
- [ ] Click en notificación para ir al detalle
- [ ] Botón "Marcar todas como leídas"
- [ ] Link a ver todas las notificaciones

**Criterios de aceptación:**
- ✅ Debe actualizar el contador en tiempo real
- ✅ Debe mostrar máximo 5 notificaciones en el dropdown
- ✅ Debe tener animación al recibir nueva notificación

---

### RN030 - Vista de Todas las Notificaciones
**Prioridad:** BAJA  
**Dependencias:** RN028, RN029  
**Descripción:** Página completa con historial de notificaciones  
**Tareas:**
- [ ] Crear `src/views/modules/Notifications/index.vue`
- [ ] Lista completa de notificaciones con paginación
- [ ] Filtros: leídas/no leídas, por tipo
- [ ] Búsqueda
- [ ] Acciones en batch (marcar varias como leídas, eliminar varias)

**Criterios de aceptación:**
- ✅ Debe tener paginación o scroll infinito
- ✅ Debe permitir filtrar por fecha
- ✅ Debe tener opción de eliminar notificaciones antiguas

---

## 🔄 FASE 8: TRANSACCIONES RECURRENTES

### RN031 - Store de Reglas Recurrentes
**Prioridad:** MEDIA  
**Dependencias:** RN001  
**Descripción:** Store para gestión de transacciones automáticas  
**Tareas:**
- [ ] Crear `src/stores/recurring.js`
- [ ] Estado: `recurringRules`, `loading`
- [ ] Función: `fetchRecurringRules()` - Obtener reglas del usuario
- [ ] Función: `createRecurringRule()` - Crear regla
- [ ] Función: `updateRecurringRule()` - Actualizar regla
- [ ] Función: `deleteRecurringRule()` - Eliminar regla
- [ ] Función: `toggleRuleStatus()` - Activar/desactivar regla
- [ ] Función: `executeRule()` - Ejecutar regla manualmente

**Criterios de aceptación:**
- ✅ Debe validar que la fecha de inicio sea posterior a hoy
- ✅ Debe calcular automáticamente la próxima ejecución
- ✅ Debe soportar todas las periodicidades

---

### RN032 - Formulario de Regla Recurrente
**Prioridad:** MEDIA  
**Dependencias:** RN031  
**Descripción:** Formulario para crear transacciones automáticas  
**Tareas:**
- [ ] Crear `src/views/modules/Recurring/components/RecurringRuleForm.vue`
- [ ] Input de nombre/descripción
- [ ] SelectButton de tipo (Gasto/Ingreso)
- [ ] Selector de cuenta
- [ ] Selector de categoría
- [ ] Input de monto (BalanceInput)
- [ ] Selector de periodicidad
- [ ] DatePicker de fecha inicio
- [ ] DatePicker de fecha fin (opcional)
- [ ] Toggle de activa/inactiva
- [ ] Preview de próximas ejecuciones (siguiente 3-5 veces)

**Criterios de aceptación:**
- ✅ Debe mostrar claramente cuándo se ejecutará la próxima vez
- ✅ Debe validar que la periodicidad sea válida
- ✅ Debe permitir especificar día del mes para periodicidad mensual

---

### RN033 - Vista de Transacciones Recurrentes
**Prioridad:** MEDIA  
**Dependencias:** RN031, RN032  
**Descripción:** Página para gestionar reglas recurrentes  
**Tareas:**
- [ ] Crear `src/views/modules/Recurring/index.vue`
- [ ] Lista de reglas agrupadas por estado (activas/inactivas)
- [ ] Card por regla mostrando: nombre, monto, frecuencia, próxima ejecución
- [ ] Toggle rápido para activar/desactivar
- [ ] Botón para ejecutar manualmente
- [ ] Click para editar
- [ ] Badge indicando gastos vs ingresos

**Criterios de aceptación:**
- ✅ Debe mostrar próxima fecha de ejecución
- ✅ Debe permitir ejecutar una regla antes de su fecha programada
- ✅ Debe actualizar la próxima ejecución después de ejecutar

---

### RN034 - Proceso Automático de Ejecución
**Prioridad:** BAJA  
**Dependencias:** RN031  
**Descripción:** Sistema para ejecutar reglas en su fecha programada  
**Tareas:**
- [ ] Función: `processRecurringRules()` - Ejecutar reglas pendientes
- [ ] Validar fecha actual vs próxima_ejecucion
- [ ] Crear transacción automáticamente
- [ ] Actualizar próxima_ejecucion
- [ ] Enviar notificación de transacción creada
- [ ] Manejar errores (saldo insuficiente, cuenta eliminada)

**Criterios de aceptación:**
- ✅ Debe ejecutarse automáticamente (Edge Function o Cron Job)
- ✅ Debe manejar múltiples reglas que vencen el mismo día
- ✅ Debe registrar en log las ejecuciones

---

## ⚙️ FASE 9: CONFIGURACIÓN Y PREFERENCIAS

### RN035 - Store de Configuración de Usuario
**Prioridad:** BAJA  
**Dependencias:** Ninguna  
**Descripción:** Store para preferencias del usuario  
**Tareas:**
- [ ] Crear `src/stores/settings.js`
- [ ] Estado: `preferences`, `loading`
- [ ] Función: `fetchPreferences()` - Obtener configuración
- [ ] Función: `updatePreferences()` - Actualizar configuración
- [ ] Preferencias: moneda predeterminada, idioma, tema, notificaciones habilitadas

**Criterios de aceptación:**
- ✅ Debe guardar preferencias en tabla `profiles` o nueva tabla
- ✅ Debe aplicar preferencias automáticamente al cargar la app

---

### RN036 - Vista de Configuración
**Prioridad:** BAJA  
**Dependencias:** RN035  
**Descripción:** Página de configuración del usuario  
**Tareas:**
- [ ] Crear `src/views/modules/Settings/index.vue`
- [ ] Sección de perfil (nombre, email, avatar)
- [ ] Sección de preferencias (moneda, idioma, tema)
- [ ] Sección de notificaciones (configurar cuáles recibir)
- [ ] Sección de seguridad (cambiar contraseña, 2FA)
- [ ] Sección de privacidad (eliminar cuenta)
- [ ] Botón de cerrar sesión

**Criterios de aceptación:**
- ✅ Debe permitir cambiar avatar usando Supabase Storage
- ✅ Debe validar cambios antes de guardar
- ✅ Debe mostrar confirmación al guardar

---

### RN037 - Gestión de Categorías Personalizadas
**Prioridad:** BAJA  
**Dependencias:** Ninguna  
**Descripción:** Permitir al usuario crear sus propias categorías  
**Tareas:**
- [ ] Agregar botón "Crear categoría" en módulo Categories
- [ ] Formulario para categoría personalizada
- [ ] Validar que no exista una categoría pública con ese nombre
- [ ] Permitir asignar a grupo de categorías existente
- [ ] Opción de compartir con grupo

**Criterios de aceptación:**
- ✅ Las categorías personales deben aparecer en selectores
- ✅ No debe interferir con categorías públicas
- ✅ Debe permitir editar/eliminar solo las propias

---

## 🔒 FASE 10: SEGURIDAD Y OPTIMIZACIÓN

### RN038 - Implementar Middleware de Autenticación
**Prioridad:** CRÍTICA  
**Dependencias:** Ninguna  
**Descripción:** Proteger rutas que requieren autenticación  
**Tareas:**
- [ ] Crear middleware en router: `requireAuth()`
- [ ] Validar sesión de Supabase antes de cada ruta protegida
- [ ] Redireccionar a login si no hay sesión
- [ ] Guardar URL de destino para redirigir después de login
- [ ] Manejar refresh de tokens automáticamente

**Criterios de aceptación:**
- ✅ Usuario no autenticado no puede acceder a rutas protegidas
- ✅ Debe preservar el destino original
- ✅ Debe refrescar token automáticamente

---

### RN039 - Optimización de Queries
**Prioridad:** MEDIA  
**Dependencias:** Todas las fases anteriores  
**Descripción:** Mejorar rendimiento de consultas a la BD  
**Tareas:**
- [ ] Implementar paginación en listas largas (transacciones, notificaciones)
- [ ] Usar `select()` específicos en lugar de `*`
- [ ] Implementar caché con TTL en stores
- [ ] Lazy loading de imágenes y componentes pesados
- [ ] Usar índices compuestos en BD donde sea necesario
- [ ] Implementar debounce en búsquedas

**Criterios de aceptación:**
- ✅ Primera carga debe ser < 3 segundos
- ✅ Scroll debe ser fluido (60 FPS)
- ✅ Búsquedas no deben ejecutarse en cada tecla

---

### RN040 - Tests Unitarios y E2E
**Prioridad:** BAJA  
**Dependencias:** Todas las fases  
**Descripción:** Implementar suite de tests  
**Tareas:**
- [ ] Configurar Vitest para tests unitarios
- [ ] Tests de stores (accounts, transactions, goals)
- [ ] Tests de componentes críticos (formularios, modales)
- [ ] Configurar Playwright para E2E
- [ ] Tests E2E: flujo de crear transacción, crear meta, invitar a grupo
- [ ] Tests de validaciones

**Criterios de aceptación:**
- ✅ Cobertura mínima del 70%
- ✅ CI/CD debe correr tests automáticamente
- ✅ Tests deben pasar antes de hacer merge

---

## 📱 FASE 11: PWA Y MÓVIL

### RN041 - Configurar PWA
**Prioridad:** MEDIA  
**Dependencias:** Ninguna  
**Descripción:** Convertir la app en PWA instalable  
**Tareas:**
- [ ] Configurar Vite PWA Plugin
- [ ] Crear manifest.json con iconos
- [ ] Implementar service worker para caché offline
- [ ] Agregar botón "Instalar app"
- [ ] Optimizar para uso offline (guardar en IndexedDB)

**Criterios de aceptación:**
- ✅ Debe poder instalarse en móvil y desktop
- ✅ Debe funcionar offline (al menos visualización de datos cacheados)
- ✅ Debe sincronizar al volver online

---

### RN042 - Optimización para Móvil
**Prioridad:** ALTA  
**Dependencias:** Todas las fases anteriores  
**Descripción:** Mejorar experiencia móvil  
**Tareas:**
- [ ] Revisar todos los formularios para móvil
- [ ] Implementar gestos táctiles (swipe para eliminar)
- [ ] Botones flotantes para acciones principales
- [ ] Bottom navigation para móvil
- [ ] Optimizar tamaños de fuente y espaciado
- [ ] Prevenir zoom en inputs

**Criterios de aceptación:**
- ✅ Toda la UI debe ser usable con una mano
- ✅ Formularios deben tener teclados apropiados (numérico para montos)
- ✅ No debe haber scroll horizontal

---

## 🎨 FASE 12: UX Y PULIDO

### RN043 - Onboarding para Nuevos Usuarios
**Prioridad:** MEDIA  
**Dependencias:** RN001  
**Descripción:** Tutorial inicial para usuarios nuevos  
**Tareas:**
- [ ] Crear flow de onboarding con tours guiados
- [ ] Paso 1: Crear primera cuenta
- [ ] Paso 2: Registrar primera transacción
- [ ] Paso 3: Crear primera meta
- [ ] Opción de "Saltar tutorial"
- [ ] Guardar estado de onboarding completado

**Criterios de aceptación:**
- ✅ Solo debe mostrarse la primera vez
- ✅ Debe ser skippable
- ✅ Debe resaltar elementos de la UI

---

### RN044 - Modo Oscuro Completo
**Prioridad:** BAJA  
**Dependencias:** Ninguna  
**Descripción:** Asegurar que todo se vea bien en modo oscuro  
**Tareas:**
- [ ] Revisar todos los componentes en modo oscuro
- [ ] Ajustar colores de gráficas para dark mode
- [ ] Asegurar contraste adecuado
- [ ] Toggle en configuración

**Criterios de aceptación:**
- ✅ Debe respetar preferencia del sistema
- ✅ Debe poder cambiarse manualmente
- ✅ Debe persistir la elección del usuario

---

### RN045 - Feedback Visual Mejorado
**Prioridad:** MEDIA  
**Dependencias:** Todas las fases  
**Descripción:** Mejorar feedback de acciones del usuario  
**Tareas:**
- [ ] Loading skeletons en lugar de spinners
- [ ] Toasts para acciones exitosas/fallidas
- [ ] Animaciones de transición suaves
- [ ] Estados vacíos con ilustraciones
- [ ] Confirmaciones para acciones destructivas

**Criterios de aceptación:**
- ✅ Usuario siempre debe saber qué está pasando
- ✅ Acciones destructivas deben confirmar
- ✅ Animaciones no deben ser molestas

---

## 🚀 FASE 13: DEPLOYMENT Y MONITOREO

### RN046 - Configurar CI/CD
**Prioridad:** ALTA  
**Dependencias:** RN040  
**Descripción:** Automatizar deployment  
**Tareas:**
- [ ] GitHub Actions para build y deploy
- [ ] Deploy automático a producción en merge a main
- [ ] Deploy de preview en PRs
- [ ] Correr tests en cada PR
- [ ] Notificaciones de deploy exitoso/fallido

**Criterios de aceptación:**
- ✅ Deploy debe ser automático
- ✅ Rollback debe ser fácil
- ✅ Preview deployments deben funcionar

---

### RN047 - Monitoreo y Analytics
**Prioridad:** MEDIA  
**Dependencias:** RN046  
**Descripción:** Implementar tracking de errores y uso  
**Tareas:**
- [ ] Integrar Sentry para error tracking
- [ ] Implementar analytics (plausible o similar)
- [ ] Tracking de eventos importantes (crear transacción, crear meta)
- [ ] Dashboard de métricas (usuarios activos, transacciones creadas)

**Criterios de aceptación:**
- ✅ Errores deben reportarse automáticamente
- ✅ Analytics debe respetar privacidad
- ✅ Debe poder ver métricas en tiempo real

---

### RN048 - Documentación Completa
**Prioridad:** MEDIA  
**Dependencias:** Todas las fases  
**Descripción:** Documentar código y funcionalidades  
**Tareas:**
- [ ] README actualizado con setup instructions
- [ ] Documentación de API (Supabase functions)
- [ ] Documentación de stores (JSDoc)
- [ ] Guía de contribución
- [ ] Manual de usuario (help center)

**Criterios de aceptación:**
- ✅ Nuevo dev debe poder hacer setup en < 30 min
- ✅ Código crítico debe estar comentado
- ✅ Debe haber guía de troubleshooting

---

## 📊 RESUMEN DE FASES

| Fase | Nombre | Requerimientos | Prioridad | Estimación |
|------|--------|----------------|-----------|------------|
| 1 | Fundamentos de Transacciones | RN001-RN005 | CRÍTICA | 2-3 semanas |
| 2 | Grupos Financieros | RN006-RN011 | ALTA | 2-3 semanas |
| 3 | División de Gastos | RN012-RN014 | ALTA | 1-2 semanas |
| 4 | Metas y Presupuestos | RN015-RN020 | ALTA | 2-3 semanas |
| 5 | Estadísticas y Análisis | RN021-RN024 | MEDIA | 1-2 semanas |
| 6 | Gestión de Crédito | RN025-RN027 | MEDIA | 1 semana |
| 7 | Notificaciones | RN028-RN030 | MEDIA | 1 semana |
| 8 | Transacciones Recurrentes | RN031-RN034 | MEDIA | 1-2 semanas |
| 9 | Configuración | RN035-RN037 | BAJA | 1 semana |
| 10 | Seguridad y Optimización | RN038-RN040 | CRÍTICA | 1-2 semanas |
| 11 | PWA y Móvil | RN041-RN042 | MEDIA | 1 semana |
| 12 | UX y Pulido | RN043-RN045 | BAJA | 1 semana |
| 13 | Deployment | RN046-RN048 | ALTA | 1 semana |

**TOTAL ESTIMADO: 16-24 semanas (4-6 meses)**

---

## 🎯 ORDEN RECOMENDADO DE IMPLEMENTACIÓN

### Sprint 1-2 (Semanas 1-4): MVP Básico
```
RN001 → RN002 → RN003 → RN004 → RN005 → RN038
```
**Entregable:** Sistema básico de transacciones funcional

### Sprint 3-4 (Semanas 5-8): Grupos y División
```
RN006 → RN007 → RN008 → RN009 → RN010 → RN011 → RN012 → RN013 → RN014
```
**Entregable:** Grupos financieros con división de gastos

### Sprint 5-6 (Semanas 9-12): Metas y Dashboard
```
RN015 → RN016 → RN017 → RN021 → RN018 → RN019 → RN020
```
**Entregable:** Sistema completo de metas y dashboard principal

### Sprint 7-8 (Semanas 13-16): Análisis y Tarjetas
```
RN022 → RN023 → RN025 → RN026 → RN027 → RN028 → RN029
```
**Entregable:** Estadísticas avanzadas y gestión de crédito

### Sprint 9-10 (Semanas 17-20): Automatización y Optimización
```
RN031 → RN032 → RN033 → RN039 → RN041 → RN042
```
**Entregable:** Transacciones recurrentes y app optimizada

### Sprint 11-12 (Semanas 21-24): Pulido y Deployment
```
RN043 → RN044 → RN045 → RN046 → RN047 → RN048 → RN030 → RN034 → RN035 → RN036 → RN037 → RN024 → RN040
```
**Entregable:** App completa, testeada y desplegada

---

## 📝 NOTAS FINALES

- **Prioridades:**
  - CRÍTICA: Debe implementarse sí o sí para el MVP
  - ALTA: Importante para funcionalidad completa
  - MEDIA: Mejora significativa de UX
  - BAJA: Nice to have

- **Dependencias:** Respetar las dependencias marcadas para evitar retrabajos

- **Flexibilidad:** El orden puede ajustarse según necesidades del negocio

- **Testing:** Hacer tests progresivamente, no al final

- **Code Reviews:** Hacer review de cada RN antes de marcar como completo
