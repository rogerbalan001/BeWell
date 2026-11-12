# Casos de prueba · QR de emergencia con la ficha médica

- **Historia de usuario:** [https://trello.com/c/hduuAJJ9](https://trello.com/c/hduuAJJ9)
- **Sprint:** Sprint 2
- **Responsables de los casos:** Miguel
- **Precondición general:** Enlace del QR de Sofía (lo imprime el seed o la pantalla "Emergencia QR").
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-QR-01 | 1 | Normal | Se ven tipo de sangre, alergias, condiciones críticas y contacto de emergencia. | ☐ Pasa ☐ Falla | |
| CP-QR-02 | 2 | Normal | No aparece nada del resto del expediente. | ☐ Pasa ☐ Falla | |
| CP-QR-03 | 3 | Normal | El enlace anterior deja de funcionar y el nuevo sí. | ☐ Pasa ☐ Falla | |
| CP-QR-04 | 1 | Límite | Se ve la ficha ampliada. | ☐ Pasa ☐ Falla | |
| CP-QR-05 | 1 | Error de usuario | Mensaje de ficha no encontrada. | ☐ Pasa ☐ Falla | |

## Detalle

### CP-QR-01 · Normal · criterio 1

- **Precondición:** Navegador sin sesión.
- **Pasos:** Abrir el enlace del QR.
- **Resultado esperado:** Se ven tipo de sangre, alergias, condiciones críticas y contacto de emergencia.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-QR-01.png`)

### CP-QR-02 · Normal · criterio 2

- **Precondición:** Misma vista.
- **Pasos:** Buscar consultas, exámenes o récipes.
- **Resultado esperado:** No aparece nada del resto del expediente.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-QR-02.png`)

### CP-QR-03 · Normal · criterio 3

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`).
- **Pasos:** Emergencia QR → regenerar.
- **Resultado esperado:** El enlace anterior deja de funcionar y el nuevo sí.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-QR-03.png`)

### CP-QR-04 · Límite · criterio 1

- **Precondición:** Sesión de `emergencia@bewell.app`.
- **Pasos:** Abrir el enlace.
- **Resultado esperado:** Se ve la ficha ampliada.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-QR-04.png`)

### CP-QR-05 · Error de usuario · criterio 1

- **Precondición:** Navegador sin sesión.
- **Pasos:** Abrir un enlace con un token inventado.
- **Resultado esperado:** Mensaje de ficha no encontrada.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-QR-05.png`)

