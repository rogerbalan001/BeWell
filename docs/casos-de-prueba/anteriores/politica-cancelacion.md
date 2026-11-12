# Casos de prueba · Política de cancelación del médico

- **Historia de usuario:** [https://trello.com/c/5h48SKkO](https://trello.com/c/5h48SKkO)
- **Sprint:** Sprint 2
- **Responsables de los casos:** Juan y Natalio
- **Precondición general:** Sesión del Dr. Ruiz (`mateo.ruiz@bewell.app`).
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-POL-01 | 1 | Normal | Se guarda la política. | ☐ Pasa ☐ Falla | |
| CP-POL-02 | 2 | Normal | La política se muestra antes de confirmar. | ☐ Pasa ☐ Falla | |
| CP-POL-03 | 3 | Normal | Reembolso del 100 %. | ☐ Pasa ☐ Falla | |
| CP-POL-04 | 3 | Límite | Se aplica la penalización de la política y se muestra el reembolso antes de confirmar. | ☐ Pasa ☐ Falla | |
| CP-POL-05 | 3 | Error de usuario | No se permite. | ☐ Pasa ☐ Falla | |

## Detalle

### CP-POL-01 · Normal · criterio 1

- **Precondición:** Horario y política.
- **Pasos:** Elegir Flexible, Moderada o Estricta y guardar.
- **Resultado esperado:** Se guarda la política.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-POL-01.png`)

### CP-POL-02 · Normal · criterio 2

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`).
- **Pasos:** Reservar con el Dr. Ruiz hasta el paso de confirmación.
- **Resultado esperado:** La política se muestra antes de confirmar.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-POL-02.png`)

### CP-POL-03 · Normal · criterio 3

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`). Cita a más horas de las mínimas de aviso.
- **Pasos:** Cancelar.
- **Resultado esperado:** Reembolso del 100 %.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-POL-03.png`)

### CP-POL-04 · Límite · criterio 3

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`). Cita dentro de las horas mínimas de aviso.
- **Pasos:** Cancelar.
- **Resultado esperado:** Se aplica la penalización de la política y se muestra el reembolso antes de confirmar.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-POL-04.png`)

### CP-POL-05 · Error de usuario · criterio 3

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`). Cita que ya comenzó.
- **Pasos:** Intentar cancelar.
- **Resultado esperado:** No se permite.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-POL-05.png`)

