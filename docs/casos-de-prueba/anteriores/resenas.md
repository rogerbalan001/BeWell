# Casos de prueba · Leer y dejar reseñas solo de consultas atendidas

- **Historia de usuario:** [https://trello.com/c/HuaGhf5d](https://trello.com/c/HuaGhf5d)
- **Sprint:** Sprint 1
- **Responsables de los casos:** Marco y Natalio
- **Precondición general:** Sofía tiene una consulta atendida con el Dr. Ruiz.
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-RES-01 | 1 | Normal | Se abre el formulario de reseña. | ☐ Pasa ☐ Falla | |
| CP-RES-02 | 1 | Error de usuario | No aparece la opción de reseñar. | ☐ Pasa ☐ Falla | |
| CP-RES-03 | 2 | Normal | La reseña se guarda y aparece en el perfil del médico. | ☐ Pasa ☐ Falla | |
| CP-RES-04 | 3 | Límite | La edición se guarda; no se puede crear una segunda reseña. | ☐ Pasa ☐ Falla | |
| CP-RES-05 | 3 | Límite | La opción "Editar" ya no está. | ☐ Pasa ☐ Falla | |

## Detalle

### CP-RES-01 · Normal · criterio 1

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`).
- **Pasos:** Detalle de la cita atendida → "Calificar consulta".
- **Resultado esperado:** Se abre el formulario de reseña.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-RES-01.png`)

### CP-RES-02 · Error de usuario · criterio 1

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`).
- **Pasos:** Abrir una cita confirmada (no atendida).
- **Resultado esperado:** No aparece la opción de reseñar.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-RES-02.png`)

### CP-RES-03 · Normal · criterio 2

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`).
- **Pasos:** Calificar de 1 a 5 puntualidad, trato, claridad e instalaciones y escribir un comentario.
- **Resultado esperado:** La reseña se guarda y aparece en el perfil del médico.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-RES-03.png`)

### CP-RES-04 · Límite · criterio 3

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`).
- **Pasos:** Editar la reseña dentro de 7 días; intentar crear otra para la misma cita.
- **Resultado esperado:** La edición se guarda; no se puede crear una segunda reseña.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-RES-04.png`)

### CP-RES-05 · Límite · criterio 3

- **Precondición:** Reseña de hace más de 7 días.
- **Pasos:** Intentar editarla.
- **Resultado esperado:** La opción "Editar" ya no está.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-RES-05.png`)

