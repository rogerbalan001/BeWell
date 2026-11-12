# Casos de prueba · Ser dueño del expediente y llevarlo de un médico a otro

- **Historia de usuario:** [https://trello.com/c/RjWbTmEU](https://trello.com/c/RjWbTmEU)
- **Sprint:** Sprint 1
- **Responsables de los casos:** Marco y Natalio
- **Precondición general:** Datos de demostración.
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-EXP-01 | 1 | Normal | Un solo expediente con eventos de todos los médicos que la atendieron. | ☐ Pasa ☐ Falla | |
| CP-EXP-02 | 2 | Normal | Se guarda y Sofía lo ve en su expediente. | ☐ Pasa ☐ Falla | |
| CP-EXP-03 | 2 | Error de usuario | Acceso denegado. | ☐ Pasa ☐ Falla | |
| CP-EXP-04 | 3 | Normal | Se descarga un PDF con todo el expediente. | ☐ Pasa ☐ Falla | |

## Detalle

### CP-EXP-01 · Normal · criterio 1

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`).
- **Pasos:** Expediente → ver la línea de tiempo con eventos de varios médicos.
- **Resultado esperado:** Un solo expediente con eventos de todos los médicos que la atendieron.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-EXP-01.png`)

### CP-EXP-02 · Normal · criterio 2

- **Precondición:** La Dra. Soto tiene permiso vigente sobre Sofía.
- **Pasos:** Entrar como la Dra. Soto → Mis pacientes → Sofía → agregar un antecedente o evento.
- **Resultado esperado:** Se guarda y Sofía lo ve en su expediente.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-EXP-02.png`)

### CP-EXP-03 · Error de usuario · criterio 2

- **Precondición:** Un médico sin permiso (Dr. Campos sin referencia aprobada).
- **Pasos:** Abrir el expediente de Sofía por URL.
- **Resultado esperado:** Acceso denegado.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-EXP-03.png`)

### CP-EXP-04 · Normal · criterio 3

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`).
- **Pasos:** Expediente → "Exportar PDF".
- **Resultado esperado:** Se descarga un PDF con todo el expediente.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-EXP-04.png`)

