# Casos de prueba · Ver quién consultó mi expediente

- **Historia de usuario:** [https://trello.com/c/Wa4C25gr](https://trello.com/c/Wa4C25gr)
- **Sprint:** Fuera de sprint
- **Responsables de los casos:** Juan y Natalio
- **Precondición general:** Sofía con un médico autorizado.
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-AUD-01 | 1 | Normal | Queda registrada la consulta. | ☐ Pasa ☐ Falla | |
| CP-AUD-02 | 2 | Normal | Se ve quién, qué y cuándo. | ☐ Pasa ☐ Falla | |
| CP-AUD-03 | 3 | Normal | Aparece la lectura del QR. | ☐ Pasa ☐ Falla | |

## Detalle

### CP-AUD-01 · Normal · criterio 1

- **Precondición:** El médico abre el expediente de Sofía.
- **Pasos:** Revisar el registro.
- **Resultado esperado:** Queda registrada la consulta.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-AUD-01.png`)

### CP-AUD-02 · Normal · criterio 2

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`).
- **Pasos:** Médicos autorizados → registro de accesos.
- **Resultado esperado:** Se ve quién, qué y cuándo.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-AUD-02.png`)

### CP-AUD-03 · Normal · criterio 3

- **Precondición:** Alguien abre el QR de emergencia de Sofía.
- **Pasos:** Ver el registro de accesos.
- **Resultado esperado:** Aparece la lectura del QR.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-AUD-03.png`)

