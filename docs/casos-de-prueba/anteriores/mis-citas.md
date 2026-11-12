# Casos de prueba · Consultar y cancelar mis citas

- **Historia de usuario:** [https://trello.com/c/gwEFVWQC](https://trello.com/c/gwEFVWQC)
- **Sprint:** Fuera de sprint
- **Responsables de los casos:** Roger y Marco
- **Precondición general:** Sesión de Sofía (`sofia.morales@bewell.app`).
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-MCI-01 | 1 | Normal | Próximas, las que esperan respuesta y el historial. | ☐ Pasa ☐ Falla | |
| CP-MCI-02 | 2 | Normal | Detalle con su política de cancelación. | ☐ Pasa ☐ Falla | |
| CP-MCI-03 | 3 | Normal | Antes de confirmar se ve el reembolso; luego la cita queda cancelada. | ☐ Pasa ☐ Falla | |
| CP-MCI-04 | 3 | Error de usuario | No se cancela. | ☐ Pasa ☐ Falla | |

## Detalle

### CP-MCI-01 · Normal · criterio 1

- **Precondición:** Mis citas.
- **Pasos:** Ver las pestañas.
- **Resultado esperado:** Próximas, las que esperan respuesta y el historial.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-MCI-01.png`)

### CP-MCI-02 · Normal · criterio 2

- **Precondición:** Mis citas.
- **Pasos:** Abrir una cita.
- **Resultado esperado:** Detalle con su política de cancelación.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-MCI-02.png`)

### CP-MCI-03 · Normal · criterio 3

- **Precondición:** Cita futura confirmada.
- **Pasos:** Cancelar → escribir el motivo.
- **Resultado esperado:** Antes de confirmar se ve el reembolso; luego la cita queda cancelada.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-MCI-03.png`)

### CP-MCI-04 · Error de usuario · criterio 3

- **Precondición:** Cancelación en curso.
- **Pasos:** Dejar el motivo vacío.
- **Resultado esperado:** No se cancela.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-MCI-04.png`)

