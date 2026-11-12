# Casos de prueba · Referir pacientes a especialistas de la red

- **Historia de usuario:** [https://trello.com/c/sOqLjCtj](https://trello.com/c/sOqLjCtj)
- **Sprint:** Sprint 1
- **Responsables de los casos:** Roger
- **Precondición general:** Datos de demostración (referencia pendiente a Cardiología).
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-REF-01 | 1 | Normal | La referencia queda pendiente de aprobación del paciente. | ☐ Pasa ☐ Falla | |
| CP-REF-02 | 1 | Error de usuario | Se pide la nota. | ☐ Pasa ☐ Falla | |
| CP-REF-03 | 2 | Normal | El especialista recibe acceso al expediente. | ☐ Pasa ☐ Falla | |
| CP-REF-04 | 2 | Error de usuario | El especialista no recibe acceso. | ☐ Pasa ☐ Falla | |
| CP-REF-05 | 3 | Normal | Sofía recibe la propuesta y puede aceptarla. | ☐ Pasa ☐ Falla | |

## Detalle

### CP-REF-01 · Normal · criterio 1

- **Precondición:** Sesión del Dr. Ruiz (`mateo.ruiz@bewell.app`).
- **Pasos:** Mis pacientes → Sofía → "Referir" → buscar Cardiología → elegir al Dr. Campos → escribir la nota clínica.
- **Resultado esperado:** La referencia queda pendiente de aprobación del paciente.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-REF-01.png`)

### CP-REF-02 · Error de usuario · criterio 1

- **Precondición:** Sesión del Dr. Ruiz (`mateo.ruiz@bewell.app`).
- **Pasos:** Intentar referir sin nota clínica.
- **Resultado esperado:** Se pide la nota.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-REF-02.png`)

### CP-REF-03 · Normal · criterio 2

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`).
- **Pasos:** Referencias → aprobar la referencia.
- **Resultado esperado:** El especialista recibe acceso al expediente.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-REF-03.png`)

### CP-REF-04 · Error de usuario · criterio 2

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`).
- **Pasos:** Rechazar una referencia.
- **Resultado esperado:** El especialista no recibe acceso.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-REF-04.png`)

### CP-REF-05 · Normal · criterio 3

- **Precondición:** Sesión del Dr. Campos (`daniel.campos@bewell.app`).
- **Pasos:** Notificaciones → abrir la referencia → proponer un horario.
- **Resultado esperado:** Sofía recibe la propuesta y puede aceptarla.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-REF-05.png`)

