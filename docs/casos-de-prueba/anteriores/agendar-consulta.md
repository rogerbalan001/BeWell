# Casos de prueba · Agendar una consulta con el especialista elegido

- **Historia de usuario:** [https://trello.com/c/tIViSw2p](https://trello.com/c/tIViSw2p)
- **Sprint:** Sprint 1
- **Responsables de los casos:** Roger y Juan
- **Precondición general:** Datos de demostración cargados. Contraseña de todas las cuentas: `Bewell2026!`.
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-AGE-01 | 1 | Normal | Solo aparecen médicos verificados de esa especialidad y modalidad; Andrés Pérez (pendiente) no aparece. | ☐ Pasa ☐ Falla | |
| CP-AGE-02 | 2 | Normal | Solo se ofrecen fechas y horas libres de su agenda. | ☐ Pasa ☐ Falla | |
| CP-AGE-03 | 2 | Límite | Solo una reserva se confirma; la otra recibe "Ese horario acaba de ser reservado. Elige otro." | ☐ Pasa ☐ Falla | |
| CP-AGE-04 | 3 | Normal | Se ven el resumen, la política de cancelación y el pago retenido; la cita aparece en Mis citas. | ☐ Pasa ☐ Falla | |
| CP-AGE-05 | 3 | Error de usuario | Vuelve al paso 2 sin crear la cita. | ☐ Pasa ☐ Falla | |

## Detalle

### CP-AGE-01 · Normal · criterio 1

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`).
- **Pasos:** Directorio → filtrar por Medicina Interna y modalidad En línea.
- **Resultado esperado:** Solo aparecen médicos verificados de esa especialidad y modalidad; Andrés Pérez (pendiente) no aparece.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-AGE-01.png`)

### CP-AGE-02 · Normal · criterio 2

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`).
- **Pasos:** Elegir a la Dra. Soto → ver horarios.
- **Resultado esperado:** Solo se ofrecen fechas y horas libres de su agenda.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-AGE-02.png`)

### CP-AGE-03 · Límite · criterio 2

- **Precondición:** Dos sesiones (Sofía y Martín) en el mismo horario.
- **Pasos:** Ambos confirman la misma franja casi a la vez.
- **Resultado esperado:** Solo una reserva se confirma; la otra recibe "Ese horario acaba de ser reservado. Elige otro."
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-AGE-03.png`)

### CP-AGE-04 · Normal · criterio 3

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`).
- **Pasos:** Confirmar la reserva.
- **Resultado esperado:** Se ven el resumen, la política de cancelación y el pago retenido; la cita aparece en Mis citas.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-AGE-04.png`)

### CP-AGE-05 · Error de usuario · criterio 3

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`).
- **Pasos:** En el paso 3 tocar "Modificar horario".
- **Resultado esperado:** Vuelve al paso 2 sin crear la cita.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-AGE-05.png`)

