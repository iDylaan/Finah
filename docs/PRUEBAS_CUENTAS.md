# Guía de Pruebas - Creación de Cuentas

## ✅ Sistema Integrado

El sistema de cuentas ya está completamente integrado con Supabase. Puedes crear los siguientes tipos de cuentas:

---

## 📝 Tipos de Cuenta Disponibles

### 1. 💵 **Efectivo (cash)**

**Campos obligatorios:**
- Nombre de la cuenta
- Saldo actual

**Campos opcionales:**
- Ubicación (Cartera, Casa, Caja fuerte, Otro)

**Ejemplo de prueba:**
```
Nombre: Mi Cartera
Tipo: Efectivo
Saldo: $500.00
Ubicación: Cartera
```

**Datos guardados en DB:**
```json
{
  "nombre": "Mi Cartera",
  "tipo": "cash",
  "saldo": 500.00,
  "metadatos": {
    "location": "wallet"
  }
}
```

---

### 2. 🏦 **Cuenta Bancaria (bank)**

**Campos obligatorios:**
- Nombre de la cuenta
- Saldo actual

**Campos opcionales:**
- Banco
- Últimos 4 dígitos de la cuenta

**Ejemplo de prueba:**
```
Nombre: Cuenta Nómina BBVA
Tipo: Cuenta Bancaria
Banco: BBVA
Últimos 4 dígitos: 1234
Saldo: $15,000.00
```

**Datos guardados en DB:**
```json
{
  "nombre": "Cuenta Nómina BBVA",
  "tipo": "bank",
  "saldo": 15000.00,
  "metadatos": {
    "banco_id": "uuid-del-banco",
    "last4": "1234"
  }
}
```

---

### 3. 💳 **Tarjeta de Débito (debit_card)**

**Campos obligatorios:**
- Nombre de la cuenta
- Saldo actual

**Campos opcionales:**
- Banco
- Últimos 4 dígitos

**Ejemplo de prueba:**
```
Nombre: Débito Santander
Tipo: Tarjeta de Débito
Banco: Santander
Últimos 4 dígitos: 5678
Saldo: $8,500.00
```

**Datos guardados en DB:**
```json
{
  "nombre": "Débito Santander",
  "tipo": "debit_card",
  "saldo": 8500.00,
  "metadatos": {
    "banco_id": "uuid-del-banco",
    "last4": "5678"
  }
}
```

---

### 4. 💳 **Tarjeta de Crédito (credit_card)**

**Campos obligatorios:**
- Nombre de la cuenta
- Banco
- Límite de crédito
- Crédito disponible
- Día de corte (1-31)
- Día de pago (1-31)

**Campos opcionales:**
- Últimos 4 dígitos
- CAT % (Costo Anual Total)
- Anualidad
- Gasto para exención de anualidad
- Tasa de interés anual
- Porcentaje de pago mínimo
- Días de gracia
- Próxima fecha de corte
- Próxima fecha de pago
- Puntos por peso gastado
- Porcentaje de cashback
- Notas adicionales (promociones, beneficios, MSI)

**Ejemplo de prueba completo:**
```
Nombre: AMEX Platinum
Tipo: Tarjeta de Crédito
Banco: American Express
Últimos 4 dígitos: 9012

=== Límites ===
Límite de crédito: $50,000.00
Crédito disponible: $50,000.00

=== Fechas ===
Día de corte: 15
Día de pago: 20
Próxima fecha de corte: 15/01/2026
Próxima fecha de pago: 20/01/2026

=== Costos ===
CAT: 45.5%
Tasa de interés: 42.0%
Anualidad: $3,500.00
Gasto para exentar anualidad: $100,000.00
Pago mínimo: 5.0%

=== Beneficios ===
Cashback: 1.5%
Puntos por peso: 2.5
Días de gracia: 20

=== Información adicional ===
Notas: "6 MSI en tiendas departamentales, 
Seguro de viaje internacional incluido,
Acceso a salas VIP en aeropuertos"
```

**Datos guardados en DB:**

**Tabla `cuentas`:**
```json
{
  "nombre": "AMEX Platinum",
  "tipo": "credit_card",
  "saldo": 0,
  "metadatos": {
    "last4": "9012"
  }
}
```

**Tabla `tarjetas_credito`:**
```json
{
  "cuenta_id": "uuid-de-la-cuenta",
  "banco_id": "uuid-del-banco",
  "nombre_tarjeta": "AMEX Platinum",
  "ultimos_cuatro_digitos": "9012",
  "limite_credito": 50000.00,
  "credito_disponible": 50000.00,
  "dia_corte": 15,
  "dia_pago": 20,
  "tasa_interes": 42.0,
  "porcentaje_pago_minimo": 5.0,
  "proxima_fecha_pago": "2026-01-20",
  "proxima_fecha_corte": "2026-01-15",
  "porcentaje_cat": 45.5,
  "anualidad": 3500.00,
  "gasto_exencion_anualidad": 100000.00,
  "porcentaje_cashback": 1.5,
  "puntos_por_peso": 2.5,
  "dias_gracia": 20,
  "notas": "6 MSI en tiendas departamentales, Seguro de viaje internacional incluido, Acceso a salas VIP en aeropuertos"
}
```

---

## 🧪 Pasos para Probar

### 1. Iniciar el servidor
```bash
npm run dev
```

### 2. Ir al módulo de Cuentas
- Navegar a `http://localhost:5173/accounts` (o la ruta que tengas configurada)

### 3. Crear una cuenta de cada tipo

**Orden recomendado:**
1. ✅ **Efectivo** - La más simple
2. ✅ **Cuenta Bancaria** - Requiere seleccionar banco
3. ✅ **Tarjeta de Débito** - Similar a cuenta bancaria
4. ✅ **Tarjeta de Crédito** - La más compleja

### 4. Verificar en Supabase

Después de crear cada cuenta, verifica en Supabase:

```sql
-- Ver todas tus cuentas
SELECT * FROM cuentas WHERE creada_por = 'tu-user-id';

-- Ver tarjetas de crédito
SELECT 
  c.nombre,
  c.tipo,
  tc.*
FROM cuentas c
LEFT JOIN tarjetas_credito tc ON tc.cuenta_id = c.id
WHERE c.creada_por = 'tu-user-id';
```

---

## ✨ Funcionalidades Implementadas

### ✅ Crear Cuentas
- Validación de formulario
- Guardado en Supabase
- Manejo de errores
- Recarga automática de lista

### ✅ Editar Cuentas
- Actualización de datos
- Preservación de tipo (no se puede cambiar tipo si tiene transacciones)

### ✅ Eliminar Cuentas
- Confirmación antes de eliminar
- Eliminación en cascada de tarjetas de crédito

### ✅ Visualización
- Lista de cuentas con información del banco
- Iconos y colores del banco
- Badges informativos
- Responsive design

---

## 🔍 Validaciones Implementadas

### Para todas las cuentas:
- ✅ Nombre obligatorio
- ✅ Saldo obligatorio
- ✅ Saldo no puede ser negativo

### Para tarjetas de crédito:
- ✅ Límite de crédito obligatorio y mayor que 0
- ✅ Crédito disponible obligatorio y no negativo
- ✅ Crédito disponible no puede exceder el límite
- ✅ Días de corte y pago entre 1 y 31

### Para últimos 4 dígitos:
- ✅ Solo acepta números
- ✅ Máximo 4 caracteres

---

## 🐛 Posibles Problemas y Soluciones

### Problema: "Usuario no autenticado"
**Solución:** Asegúrate de estar logueado en Supabase

### Problema: No se muestra el banco
**Solución:** Verifica que el banco exista en la tabla `bancos` y que sea público o creado por ti

### Problema: Error al crear tarjeta de crédito
**Solución:** 
1. Verifica que el banco_id exista
2. Verifica que el límite de crédito sea mayor que 0
3. Verifica que el crédito disponible no exceda el límite

### Problema: Los datos no se actualizan en la lista
**Solución:** El sistema usa caché. Haz clic en el botón "Actualizar" (🔄)

---

## 📊 Esquema de Datos

### Campo `tipo` en tabla `cuentas`
```
'cash'        - Efectivo
'bank'        - Cuenta Bancaria
'debit_card'  - Tarjeta de Débito
'credit_card' - Tarjeta de Crédito
```

### Campo `metadatos` (JSONB)
```json
{
  "banco_id": "uuid",      // Para bank y debit_card
  "last4": "1234",         // Últimos 4 dígitos
  "location": "wallet",    // Solo para cash
  "hasRewards": false,     // Flags adicionales
  "hasInsurance": false,
  "hasCashback": false
}
```

---

## 🎯 Próximos Pasos

Una vez que hayas probado la creación de cuentas:

1. ✅ Verificar que las cuentas se guardan correctamente en Supabase
2. ✅ Probar edición de cuentas
3. ✅ Probar eliminación de cuentas
4. 🔜 Implementar módulo de Transacciones
5. 🔜 Vincular transacciones con cuentas
6. 🔜 Actualización automática de saldos

---

## 💡 Notas Importantes

1. **Banco es opcional** para efectivo, pero recomendado para cuentas bancarias y tarjetas
2. **Solo tarjetas de crédito** usan la tabla `tarjetas_credito`
3. **El saldo se actualiza automáticamente** cuando registres transacciones (próxima funcionalidad)
4. **Los metadatos son flexibles** - puedes agregar más campos según necesites
5. **Las cuentas están asociadas al usuario** que las crea (RLS de Supabase)

---

## 🚀 Comandos Útiles

```bash
# Iniciar servidor de desarrollo
npm run dev

# Ver logs de Supabase (si tienes CLI)
supabase logs

# Verificar conexión a base de datos
# Desde la consola de navegador:
const { data, error } = await supabase.from('cuentas').select('*')
console.log({ data, error })
```

---

¡Listo para crear tus primeras cuentas! 🎉
