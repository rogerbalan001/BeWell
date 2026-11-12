# Casos de prueba · Ver la agenda y registrar el resultado de cada cita

- **Historia de usuario:** [https://trello.com/c/3l7pCkXb](https://trello.com/c/3l7pCkXb)
- **Sprint:** Fuera de sprint
- **Responsables de los casos:** Roger y Marco
- **Precondición general:** Sesión del Dr. Ruiz (`mateo.ruiz@bewell.app`). Cita de demostración que empezó hace 10 minutos.
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-AGM-01 | 1 | Normal | Aparecen sus citas. | ☐ Pasa ☐ Falla | |
| CP-AGM-02 | 2 | Normal | La cita queda atendida y se registra en el expediente. | ☐ Pasa ☐ Falla | |
| CP-AGM-03 | 2 | Límite | No se permite antes de su hora. | ☐ Pasa ☐ Falla | |
| CP-AGM-04 | 3 | Normal | Queda registrada la inasistencia. | ☐ Pasa ☐ Falla | |

## Detalle

### CP-AGM-01 · Normal · criterio 1

- **Precondición:** Menú → Agenda.
- **Pasos:** Ver las citas del día.
- **Resultado esperado:** Aparecen sus citas.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-AGM-01.png`)

### CP-AGM-02 · Normal · criterio 2

- **Precondición:** Cita en curso.
- **Pasos:** "Marcar como atendida" con nota y diagnóstico.
- **Resultado esperado:** La cita queda atendida y se registra en el expediente.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-AGM-02.png`)

### CP-AGM-03 · Límite · criterio 2

- **Precondición:** Cita que empieza en 2 horas.
- **Pasos:** Intentar marcarla como atendida.
- **Resultado esperado:** No se permite antes de su hora.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-AGM-03.png`)

### CP-AGM-04 · Normal · criterio 3

- **Precondición:** Cita que ya pasó.
- **Pasos:** "No asistió".
- **Resultado esperado:** Queda registrada la inasistencia.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-AGM-04.png`)

