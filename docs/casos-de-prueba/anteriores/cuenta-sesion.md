# Casos de prueba · Crear cuenta como paciente o médico e iniciar sesión

- **Historia de usuario:** [https://trello.com/c/IS3Dd6iI](https://trello.com/c/IS3Dd6iI)
- **Sprint:** Fuera de sprint
- **Responsables de los casos:** Juan y Miguel
- **Precondición general:** Navegador sin sesión.
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-CTA-01 | 1 | Normal | Cada formulario pide los datos de su tipo y la cuenta queda creada. | ☐ Pasa ☐ Falla | |
| CP-CTA-02 | 1 | Error de usuario | Mensaje claro y no se crea la cuenta. | ☐ Pasa ☐ Falla | |
| CP-CTA-03 | 2 | Normal | La sesión se mantiene sola y se cierra desde el menú. | ☐ Pasa ☐ Falla | |
| CP-CTA-04 | 2 | Error de usuario | "Credenciales inválidas". | ☐ Pasa ☐ Falla | |
| CP-CTA-05 | 3 | Normal | El menú no la muestra y la API responde 403. | ☐ Pasa ☐ Falla | |

## Detalle

### CP-CTA-01 · Normal · criterio 1

- **Precondición:** Página de acceso.
- **Pasos:** Crear cuenta de paciente; luego una de médico.
- **Resultado esperado:** Cada formulario pide los datos de su tipo y la cuenta queda creada.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-CTA-01.png`)

### CP-CTA-02 · Error de usuario · criterio 1

- **Precondición:** Formulario de registro.
- **Pasos:** Usar un correo ya registrado o una contraseña corta.
- **Resultado esperado:** Mensaje claro y no se crea la cuenta.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-CTA-02.png`)

### CP-CTA-03 · Normal · criterio 2

- **Precondición:** Cuenta creada.
- **Pasos:** Iniciar sesión, cerrar la pestaña y volver a abrir la app; luego "Cerrar sesión".
- **Resultado esperado:** La sesión se mantiene sola y se cierra desde el menú.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-CTA-03.png`)

### CP-CTA-04 · Error de usuario · criterio 2

- **Precondición:** Página de acceso.
- **Pasos:** Contraseña incorrecta.
- **Resultado esperado:** "Credenciales inválidas".
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-CTA-04.png`)

### CP-CTA-05 · Normal · criterio 3

- **Precondición:** Sesión de paciente.
- **Pasos:** Abrir `/#/admin/verificaciones` o llamar a la API de médico.
- **Resultado esperado:** El menú no la muestra y la API responde 403.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-CTA-05.png`)

