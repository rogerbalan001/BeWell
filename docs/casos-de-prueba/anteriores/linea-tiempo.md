# Casos de prueba · Línea de tiempo del paciente para el médico

- **Historia de usuario:** [https://trello.com/c/NT1pP2u6](https://trello.com/c/NT1pP2u6)
- **Sprint:** Sprint 2
- **Responsables de los casos:** Marco y Roger
- **Precondición general:** Sesión del Dr. Ruiz (`mateo.ruiz@bewell.app`). Paciente Sofía con permiso vigente.
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-LT-01 | 1 | Normal | Eventos del más reciente al más antiguo; "Mostrando N de M eventos". | ☐ Pasa ☐ Falla | |
| CP-LT-02 | 1 | Límite | Se cargan todos y el botón desaparece. | ☐ Pasa ☐ Falla | |
| CP-LT-03 | 2 | Normal | Solo se ven los eventos de ese tipo. | ☐ Pasa ☐ Falla | |
| CP-LT-04 | 3 | Normal | Se abre el detalle con los datos en palabras (sin códigos internos). | ☐ Pasa ☐ Falla | |

## Detalle

### CP-LT-01 · Normal · criterio 1

- **Precondición:** Expediente de Sofía.
- **Pasos:** Ver la línea de tiempo.
- **Resultado esperado:** Eventos del más reciente al más antiguo; "Mostrando N de M eventos".
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-LT-01.png`)

### CP-LT-02 · Límite · criterio 1

- **Precondición:** Paciente con más de 50 eventos.
- **Pasos:** Tocar "Ver eventos anteriores" hasta el final.
- **Resultado esperado:** Se cargan todos y el botón desaparece.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-LT-02.png`)

### CP-LT-03 · Normal · criterio 2

- **Precondición:** Línea de tiempo.
- **Pasos:** Filtrar por Examen y luego por Consulta.
- **Resultado esperado:** Solo se ven los eventos de ese tipo.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-LT-03.png`)

### CP-LT-04 · Normal · criterio 3

- **Precondición:** Línea de tiempo.
- **Pasos:** Tocar un evento.
- **Resultado esperado:** Se abre el detalle con los datos en palabras (sin códigos internos).
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-LT-04.png`)

