# Casos de prueba · Chatear de forma privada con el médico de la cita

- **Historia de usuario:** [https://trello.com/c/TdcNb1Jm](https://trello.com/c/TdcNb1Jm)
- **Sprint:** Sprint 3
- **Responsables de los casos:** Roger y Samir
- **Precondición general:** Cita confirmada de Sofía con la Dra. Soto (`valentina.soto@bewell.app`). Dos navegadores o dispositivos.
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-CHAT-01 | 1 | Normal | El mensaje aparece a la derecha con fecha y hora. | ☐ Pasa ☐ Falla | |
| CP-CHAT-02 | 1 | Error de usuario | Error de acceso: no ve los mensajes. | ☐ Pasa ☐ Falla | |
| CP-CHAT-03 | 1 | Límite | Se leen los mensajes anteriores, pero no hay campo para escribir ("El chat solo está disponible para citas confirmadas o atendidas"). | ☐ Pasa ☐ Falla | |
| CP-CHAT-04 | 1 | Límite | Se puede seguir escribiendo después de la consulta. | ☐ Pasa ☐ Falla | |
| CP-CHAT-05 | 2 | Normal | La respuesta aparece en la pantalla de Sofía en máximo 5 segundos, sin recargar, debajo del mensaje anterior. | ☐ Pasa ☐ Falla | |
| CP-CHAT-06 | 2 | Error de usuario | No se envía nada. | ☐ Pasa ☐ Falla | |
| CP-CHAT-07 | 2 | Límite | El campo no deja pasar de 2000 caracteres. | ☐ Pasa ☐ Falla | |
| CP-CHAT-08 | 3 | Normal | Notificación "Nuevo mensaje de tu paciente" (al tocarla abre el chat) y el botón muestra "(1 sin leer)". | ☐ Pasa ☐ Falla | |
| CP-CHAT-09 | 3 | Normal | El contador desaparece; Sofía ve "Leído" en sus mensajes. | ☐ Pasa ☐ Falla | |

## Detalle

### CP-CHAT-01 · Normal · criterio 1

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`, contraseña `Bewell2026!`).
- **Pasos:** Detalle de la cita confirmada → "Chat con el médico" → escribir "¿Debo ir en ayunas?" → enviar.
- **Resultado esperado:** El mensaje aparece a la derecha con fecha y hora.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-CHAT-01.png`)

### CP-CHAT-02 · Error de usuario · criterio 1

- **Precondición:** Sesión de Martín (`martin.alvarez@bewell.app`), que no es parte de la cita.
- **Pasos:** Abrir `/#/citas/<id de la cita de Sofía>/chat`.
- **Resultado esperado:** Error de acceso: no ve los mensajes.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-CHAT-02.png`)

### CP-CHAT-03 · Límite · criterio 1

- **Precondición:** Cita cancelada que tenía mensajes.
- **Pasos:** Abrir el chat.
- **Resultado esperado:** Se leen los mensajes anteriores, pero no hay campo para escribir ("El chat solo está disponible para citas confirmadas o atendidas").
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-CHAT-03.png`)

### CP-CHAT-04 · Límite · criterio 1

- **Precondición:** Cita atendida.
- **Pasos:** Escribir en el chat.
- **Resultado esperado:** Se puede seguir escribiendo después de la consulta.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-CHAT-04.png`)

### CP-CHAT-05 · Normal · criterio 2

- **Precondición:** Sofía y la Dra. Soto con el chat abierto a la vez.
- **Pasos:** La doctora responde.
- **Resultado esperado:** La respuesta aparece en la pantalla de Sofía en máximo 5 segundos, sin recargar, debajo del mensaje anterior.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-CHAT-05.png`)

### CP-CHAT-06 · Error de usuario · criterio 2

- **Precondición:** Chat abierto.
- **Pasos:** Intentar enviar un mensaje vacío o solo con espacios.
- **Resultado esperado:** No se envía nada.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-CHAT-06.png`)

### CP-CHAT-07 · Límite · criterio 2

- **Precondición:** Chat abierto.
- **Pasos:** Pegar un texto de más de 2000 caracteres.
- **Resultado esperado:** El campo no deja pasar de 2000 caracteres.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-CHAT-07.png`)

### CP-CHAT-08 · Normal · criterio 3

- **Precondición:** Sofía envía un mensaje con la doctora fuera del chat.
- **Pasos:** Entrar como la doctora → Notificaciones; luego abrir el detalle de la cita.
- **Resultado esperado:** Notificación "Nuevo mensaje de tu paciente" (al tocarla abre el chat) y el botón muestra "(1 sin leer)".
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-CHAT-08.png`)

### CP-CHAT-09 · Normal · criterio 3

- **Precondición:** Mensajes sin leer.
- **Pasos:** Abrir el chat y volver al detalle.
- **Resultado esperado:** El contador desaparece; Sofía ve "Leído" en sus mensajes.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-CHAT-09.png`)

