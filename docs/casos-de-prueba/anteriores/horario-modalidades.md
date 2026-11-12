# Casos de prueba · Configurar horario semanal y modalidades

- **Historia de usuario:** [https://trello.com/c/JkFElhnQ](https://trello.com/c/JkFElhnQ)
- **Sprint:** Fuera de sprint
- **Responsables de los casos:** Juan y Samir
- **Precondición general:** Sesión del Dr. Ruiz (`mateo.ruiz@bewell.app`).
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-HOR-01 | 1 | Normal | Se guarda el horario. | ☐ Pasa ☐ Falla | |
| CP-HOR-02 | 1 | Error de usuario | Se rechaza con un mensaje. | ☐ Pasa ☐ Falla | |
| CP-HOR-03 | 2 | Normal | El paciente solo puede reservar en línea. | ☐ Pasa ☐ Falla | |
| CP-HOR-04 | 3 | Normal | Solo aparecen franjas dentro de los bloques configurados. | ☐ Pasa ☐ Falla | |

## Detalle

### CP-HOR-01 · Normal · criterio 1

- **Precondición:** Horario y política.
- **Pasos:** Definir bloques por día y duración de cita; guardar.
- **Resultado esperado:** Se guarda el horario.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-HOR-01.png`)

### CP-HOR-02 · Error de usuario · criterio 1

- **Precondición:** Horario.
- **Pasos:** Poner una hora de fin anterior a la de inicio.
- **Resultado esperado:** Se rechaza con un mensaje.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-HOR-02.png`)

### CP-HOR-03 · Normal · criterio 2

- **Precondición:** Horario.
- **Pasos:** Elegir solo "En línea".
- **Resultado esperado:** El paciente solo puede reservar en línea.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-HOR-03.png`)

### CP-HOR-04 · Normal · criterio 3

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`).
- **Pasos:** Ver los horarios del Dr. Ruiz.
- **Resultado esperado:** Solo aparecen franjas dentro de los bloques configurados.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-HOR-04.png`)

