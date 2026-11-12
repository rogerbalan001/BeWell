# Casos de prueba · Centro de notificaciones

- **Historia de usuario:** [https://trello.com/c/P9m2dhnH](https://trello.com/c/P9m2dhnH)
- **Sprint:** Fuera de sprint
- **Responsables de los casos:** Juan y Samir
- **Precondición general:** Sesión de Sofía (`sofia.morales@bewell.app`). Avisos de citas, exámenes, récipes y recordatorios.
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-NOT-01 | 1 | Normal | Todos los tipos en una sola lista. | ☐ Pasa ☐ Falla | |
| CP-NOT-02 | 2 | Normal | Se actualiza el contador. | ☐ Pasa ☐ Falla | |
| CP-NOT-03 | 3 | Normal | Abren la cita, los récipes y el chat. | ☐ Pasa ☐ Falla | |
| CP-NOT-04 | 1 | Límite | Estado vacío con mensaje. | ☐ Pasa ☐ Falla | |

## Detalle

### CP-NOT-01 · Normal · criterio 1

- **Precondición:** Notificaciones.
- **Pasos:** Ver la bandeja.
- **Resultado esperado:** Todos los tipos en una sola lista.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-NOT-01.png`)

### CP-NOT-02 · Normal · criterio 2

- **Precondición:** Avisos sin leer.
- **Pasos:** Marcar uno como leído; luego "Marcar todos".
- **Resultado esperado:** Se actualiza el contador.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-NOT-02.png`)

### CP-NOT-03 · Normal · criterio 3

- **Precondición:** Aviso de cita, de récipe y de chat.
- **Pasos:** Tocarlos.
- **Resultado esperado:** Abren la cita, los récipes y el chat.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-NOT-03.png`)

### CP-NOT-04 · Límite · criterio 1

- **Precondición:** Cuenta nueva.
- **Pasos:** Abrir Notificaciones.
- **Resultado esperado:** Estado vacío con mensaje.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-NOT-04.png`)

