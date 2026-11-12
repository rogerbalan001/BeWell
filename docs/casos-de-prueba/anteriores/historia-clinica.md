# Casos de prueba · Historia clínica completa del paciente

- **Historia de usuario:** [https://trello.com/c/lP5Xrde3](https://trello.com/c/lP5Xrde3)
- **Sprint:** Sprint 2
- **Responsables de los casos:** Samir
- **Precondición general:** Sesión del Dr. Ruiz (`mateo.ruiz@bewell.app`). Paciente Sofía con permiso.
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-HC-01 | 1 | Normal | Se guardan y se ven en la vista tipo documento. | ☐ Pasa ☐ Falla | |
| CP-HC-02 | 2 | Normal | Se guarda; el IMC se calcula con peso y talla. | ☐ Pasa ☐ Falla | |
| CP-HC-03 | 2 | Límite | No se permite. | ☐ Pasa ☐ Falla | |
| CP-HC-04 | 2 | Error de usuario | Se pide corregir los datos. | ☐ Pasa ☐ Falla | |
| CP-HC-05 | 3 | Normal | Se descarga el PDF completo. | ☐ Pasa ☐ Falla | |

## Detalle

### CP-HC-01 · Normal · criterio 1

- **Precondición:** Historia clínica de Sofía.
- **Pasos:** Registrar antecedentes personales, familiares y sociales.
- **Resultado esperado:** Se guardan y se ven en la vista tipo documento.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-HC-01.png`)

### CP-HC-02 · Normal · criterio 2

- **Precondición:** Consulta atendida.
- **Pasos:** Registrar la consulta con motivo, enfermedad actual, signos vitales, diagnóstico y plan.
- **Resultado esperado:** Se guarda; el IMC se calcula con peso y talla.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-HC-02.png`)

### CP-HC-03 · Límite · criterio 2

- **Precondición:** Consulta registrada hace más de 24 h.
- **Pasos:** Intentar corregirla.
- **Resultado esperado:** No se permite.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-HC-03.png`)

### CP-HC-04 · Error de usuario · criterio 2

- **Precondición:** Formulario de consulta.
- **Pasos:** Guardar sin motivo o con signos vitales fuera de rango.
- **Resultado esperado:** Se pide corregir los datos.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-HC-04.png`)

### CP-HC-05 · Normal · criterio 3

- **Precondición:** Historia clínica.
- **Pasos:** Exportar PDF.
- **Resultado esperado:** Se descarga el PDF completo.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-HC-05.png`)

