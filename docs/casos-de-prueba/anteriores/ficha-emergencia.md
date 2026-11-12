# Casos de prueba · Completar la ficha de emergencia y elegir qué muestra el QR

- **Historia de usuario:** [https://trello.com/c/pIt44NCG](https://trello.com/c/pIt44NCG)
- **Sprint:** Fuera de sprint
- **Responsables de los casos:** Roger y Samir
- **Precondición general:** Sesión de Sofía (`sofia.morales@bewell.app`).
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-FIC-01 | 1 | Normal | Se guarda la ficha. | ☐ Pasa ☐ Falla | |
| CP-FIC-02 | 1 | Error de usuario | Se pide completarlo. | ☐ Pasa ☐ Falla | |
| CP-FIC-03 | 2 | Normal | En el enlace sin sesión ya no se ve la medicación. | ☐ Pasa ☐ Falla | |
| CP-FIC-04 | 3 | Normal | La app muestra el QR y su enlace. | ☐ Pasa ☐ Falla | |

## Detalle

### CP-FIC-01 · Normal · criterio 1

- **Precondición:** Emergencia QR.
- **Pasos:** Registrar grupo sanguíneo, alergias, condiciones, medicación y contactos.
- **Resultado esperado:** Se guarda la ficha.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-FIC-01.png`)

### CP-FIC-02 · Error de usuario · criterio 1

- **Precondición:** Ficha.
- **Pasos:** Guardar un contacto sin teléfono.
- **Resultado esperado:** Se pide completarlo.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-FIC-02.png`)

### CP-FIC-03 · Normal · criterio 2

- **Precondición:** Ficha.
- **Pasos:** Ocultar la medicación del QR público.
- **Resultado esperado:** En el enlace sin sesión ya no se ve la medicación.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-FIC-03.png`)

### CP-FIC-04 · Normal · criterio 3

- **Precondición:** Emergencia QR.
- **Pasos:** Ver el código.
- **Resultado esperado:** La app muestra el QR y su enlace.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-FIC-04.png`)

