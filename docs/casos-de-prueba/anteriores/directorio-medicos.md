# Casos de prueba · Buscar médicos y ver su perfil

- **Historia de usuario:** [https://trello.com/c/ToRAAFcJ](https://trello.com/c/ToRAAFcJ)
- **Sprint:** Fuera de sprint
- **Responsables de los casos:** Juan y Samir
- **Precondición general:** Sesión de Sofía (`sofia.morales@bewell.app`).
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-DIR-01 | 1 | Normal | Resultados que cumplen la búsqueda y los filtros. | ☐ Pasa ☐ Falla | |
| CP-DIR-02 | 1 | Límite | Estado vacío con mensaje. | ☐ Pasa ☐ Falla | |
| CP-DIR-03 | 2 | Normal | Ordenados por calificación y número de reseñas. | ☐ Pasa ☐ Falla | |
| CP-DIR-04 | 3 | Normal | Se ven tarifa, modalidades, política de cancelación, reseñas y el botón para reservar. | ☐ Pasa ☐ Falla | |

## Detalle

### CP-DIR-01 · Normal · criterio 1

- **Precondición:** Directorio.
- **Pasos:** Buscar "Soto" y luego filtrar por especialidad y modalidad.
- **Resultado esperado:** Resultados que cumplen la búsqueda y los filtros.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-DIR-01.png`)

### CP-DIR-02 · Límite · criterio 1

- **Precondición:** Directorio.
- **Pasos:** Buscar un nombre que no existe.
- **Resultado esperado:** Estado vacío con mensaje.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-DIR-02.png`)

### CP-DIR-03 · Normal · criterio 2

- **Precondición:** Directorio sin filtros.
- **Pasos:** Ver el orden.
- **Resultado esperado:** Ordenados por calificación y número de reseñas.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-DIR-03.png`)

### CP-DIR-04 · Normal · criterio 3

- **Precondición:** Directorio.
- **Pasos:** Abrir un perfil.
- **Resultado esperado:** Se ven tarifa, modalidades, política de cancelación, reseñas y el botón para reservar.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-DIR-04.png`)

