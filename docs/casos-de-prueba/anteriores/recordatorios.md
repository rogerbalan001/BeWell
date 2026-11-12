# Casos de prueba · Recordatorios de citas, medicamentos y exámenes

- **Historia de usuario:** [https://trello.com/c/nGAwU33i](https://trello.com/c/nGAwU33i)
- **Sprint:** Sprint 2
- **Responsables de los casos:** Roger y Natalio
- **Precondición general:** Sesión de Sofía (`sofia.morales@bewell.app`). Cita confirmada en los próximos días y récipe vigente.
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-RCD-01 | 1 | Normal | Aparecen los avisos 24 h y 1 h antes; a esa hora llegan a Notificaciones. | ☐ Pasa ☐ Falla | |
| CP-RCD-02 | 2 | Normal | Aparece un recordatorio por cada toma. | ☐ Pasa ☐ Falla | |
| CP-RCD-03 | 3 | Normal | Desaparecen los recordatorios de medicamentos; las citas siguen. | ☐ Pasa ☐ Falla | |
| CP-RCD-04 | 3 | Límite | No llega ese recordatorio y no llega duplicado ningún otro. | ☐ Pasa ☐ Falla | |

## Detalle

### CP-RCD-01 · Normal · criterio 1

- **Precondición:** Cita para mañana.
- **Pasos:** Recordatorios → "Próximos 7 días".
- **Resultado esperado:** Aparecen los avisos 24 h y 1 h antes; a esa hora llegan a Notificaciones.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-RCD-01.png`)

### CP-RCD-02 · Normal · criterio 2

- **Precondición:** Récipe "cada 8 h".
- **Pasos:** Ver "Próximos 7 días".
- **Resultado esperado:** Aparece un recordatorio por cada toma.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-RCD-02.png`)

### CP-RCD-03 · Normal · criterio 3

- **Precondición:** Recordatorios abiertos.
- **Pasos:** Apagar "Medicamentos".
- **Resultado esperado:** Desaparecen los recordatorios de medicamentos; las citas siguen.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-RCD-03.png`)

### CP-RCD-04 · Límite · criterio 3

- **Precondición:** Medicamentos apagados.
- **Pasos:** Esperar a la hora de una toma.
- **Resultado esperado:** No llega ese recordatorio y no llega duplicado ningún otro.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-RCD-04.png`)

