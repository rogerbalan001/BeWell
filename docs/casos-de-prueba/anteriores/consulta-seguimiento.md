# Casos de prueba · Consulta de seguimiento aceptada por ambas partes

- **Historia de usuario:** [https://trello.com/c/0zVqAZs2](https://trello.com/c/0zVqAZs2)
- **Sprint:** Sprint 1
- **Responsables de los casos:** Juan
- **Precondición general:** Consulta atendida de Sofía con el Dr. Ruiz.
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-SEG-01 | 1 | Normal | La cita queda "Pendiente de aceptación". | ☐ Pasa ☐ Falla | |
| CP-SEG-02 | 2 | Normal | La cita queda confirmada. | ☐ Pasa ☐ Falla | |
| CP-SEG-03 | 2 | Error de usuario | No se permite: la debe aceptar la otra parte. | ☐ Pasa ☐ Falla | |
| CP-SEG-04 | 3 | Normal | Se cancela y ambos reciben la notificación. | ☐ Pasa ☐ Falla | |
| CP-SEG-05 | 3 | Límite | Se cancela sola y se notifica a ambos. | ☐ Pasa ☐ Falla | |

## Detalle

### CP-SEG-01 · Normal · criterio 1

- **Precondición:** Sesión del Dr. Ruiz (`mateo.ruiz@bewell.app`).
- **Pasos:** Detalle de la cita atendida → "Proponer seguimiento" → elegir horario disponible.
- **Resultado esperado:** La cita queda "Pendiente de aceptación".
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-SEG-01.png`)

### CP-SEG-02 · Normal · criterio 2

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`).
- **Pasos:** Abrir la propuesta → "Aceptar propuesta".
- **Resultado esperado:** La cita queda confirmada.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-SEG-02.png`)

### CP-SEG-03 · Error de usuario · criterio 2

- **Precondición:** Sesión del Dr. Ruiz (`mateo.ruiz@bewell.app`).
- **Pasos:** Intentar aceptar su propia propuesta.
- **Resultado esperado:** No se permite: la debe aceptar la otra parte.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-SEG-03.png`)

### CP-SEG-04 · Normal · criterio 3

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`).
- **Pasos:** Rechazar una propuesta.
- **Resultado esperado:** Se cancela y ambos reciben la notificación.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-SEG-04.png`)

### CP-SEG-05 · Límite · criterio 3

- **Precondición:** Propuesta sin respuesta.
- **Pasos:** Esperar 48 horas.
- **Resultado esperado:** Se cancela sola y se notifica a ambos.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-SEG-05.png`)

