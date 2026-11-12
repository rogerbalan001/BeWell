# Casos de prueba · Solicitar exámenes y recibir los resultados en el expediente

- **Historia de usuario:** [https://trello.com/c/nbuV01WE](https://trello.com/c/nbuV01WE)
- **Sprint:** Sprint 2
- **Responsables de los casos:** Miguel
- **Precondición general:** Consulta atendida de Sofía con el Dr. Ruiz.
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-SOL-01 | 1 | Normal | Se crea la orden. | ☐ Pasa ☐ Falla | |
| CP-SOL-02 | 1 | Error de usuario | No se permite. | ☐ Pasa ☐ Falla | |
| CP-SOL-03 | 2 | Normal | La orden aparece con estado "Pendiente". | ☐ Pasa ☐ Falla | |
| CP-SOL-04 | 3 | Normal | La orden pasa a "Resultados cargados" y el Dr. Ruiz recibe "Resultados disponibles". | ☐ Pasa ☐ Falla | |
| CP-SOL-05 | 3 | Límite | Se rechaza: la orden fue anulada. | ☐ Pasa ☐ Falla | |

## Detalle

### CP-SOL-01 · Normal · criterio 1

- **Precondición:** Sesión del Dr. Ruiz (`mateo.ruiz@bewell.app`).
- **Pasos:** Detalle de la cita → "Solicitar exámenes" → elegir del catálogo → generar.
- **Resultado esperado:** Se crea la orden.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-SOL-01.png`)

### CP-SOL-02 · Error de usuario · criterio 1

- **Precondición:** Sesión del Dr. Ruiz (`mateo.ruiz@bewell.app`).
- **Pasos:** Intentar generar la orden sin elegir exámenes.
- **Resultado esperado:** No se permite.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-SOL-02.png`)

### CP-SOL-03 · Normal · criterio 2

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`).
- **Pasos:** Expediente → línea de tiempo.
- **Resultado esperado:** La orden aparece con estado "Pendiente".
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-SOL-03.png`)

### CP-SOL-04 · Normal · criterio 3

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`).
- **Pasos:** Exámenes → subir el resultado de esa orden.
- **Resultado esperado:** La orden pasa a "Resultados cargados" y el Dr. Ruiz recibe "Resultados disponibles".
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-SOL-04.png`)

### CP-SOL-05 · Límite · criterio 3

- **Precondición:** El médico anuló la orden.
- **Pasos:** Intentar subir un resultado asociado a esa orden.
- **Resultado esperado:** Se rechaza: la orden fue anulada.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-SOL-05.png`)

