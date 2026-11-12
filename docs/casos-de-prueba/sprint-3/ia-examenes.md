# Casos de prueba · Deducir la categoría y el tipo del examen al subirlo (Gemini)

- **Historia de usuario:** [https://trello.com/c/Q46PaNjV](https://trello.com/c/Q46PaNjV)
- **Sprint:** Sprint 3
- **Responsables de los casos:** Juan y Miguel
- **Precondición general:** Sesión de Sofía (`sofia.morales@bewell.app`, contraseña `Bewell2026!`). API con `IA_EXAMENES=gemini` y `GEMINI_API_KEY`. Tener a mano la foto de un perfil lipídico, un PDF de hematología y una foto que no sea un examen.
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-IAX-01 | 1 | Normal | En la revisión aparece "Sugerido por la app · NN %" con Laboratorio clínico / Perfil lipídico, y el examen se llama "Perfil lipídico". | ☐ Pasa ☐ Falla | |
| CP-IAX-02 | 1 | Normal | Sugiere Hematología completa y muestra los valores detectados para revisar. | ☐ Pasa ☐ Falla | |
| CP-IAX-03 | 1 | Límite | Se conserva "Control de marzo" como nombre; igual se sugiere la categoría y el tipo. | ☐ Pasa ☐ Falla | |
| CP-IAX-04 | 2 | Normal | Se guarda la corrección; en la lista y en la línea de tiempo el examen aparece como Radiografía de tórax. | ☐ Pasa ☐ Falla | |
| CP-IAX-05 | 2 | Error de usuario | Aviso "Elige la categoría y el tipo del examen"; no se guarda. | ☐ Pasa ☐ Falla | |
| CP-IAX-06 | 2 | Límite | Se guarda con la categoría Otro y ese tipo. | ☐ Pasa ☐ Falla | |
| CP-IAX-07 | 3 | Normal | El examen se guarda igual ("Examen sin clasificar") y la revisión pide elegir la categoría y el tipo. | ☐ Pasa ☐ Falla | |
| CP-IAX-08 | 3 | Límite | La carga termina igual en pocos segundos; queda sin clasificar y el paciente elige. | ☐ Pasa ☐ Falla | |
| CP-IAX-09 | 3 | Error de usuario | "El archivo supera el máximo de 10 MB" o "Formato no permitido". | ☐ Pasa ☐ Falla | |

## Detalle

### CP-IAX-01 · Normal · criterio 1

- **Precondición:** Perfil activo: Sofía.
- **Pasos:** Exámenes → Subir examen → dejar el nombre vacío → elegir la foto del perfil lipídico → "Subir y analizar".
- **Resultado esperado:** En la revisión aparece "Sugerido por la app · NN %" con Laboratorio clínico / Perfil lipídico, y el examen se llama "Perfil lipídico".
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-IAX-01.png`)

### CP-IAX-02 · Normal · criterio 1

- **Precondición:** PDF de hematología.
- **Pasos:** Subir sin nombre.
- **Resultado esperado:** Sugiere Hematología completa y muestra los valores detectados para revisar.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-IAX-02.png`)

### CP-IAX-03 · Límite · criterio 1

- **Precondición:** Escribir un nombre propio ("Control de marzo").
- **Pasos:** Subir el perfil lipídico con ese nombre.
- **Resultado esperado:** Se conserva "Control de marzo" como nombre; igual se sugiere la categoría y el tipo.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-IAX-03.png`)

### CP-IAX-04 · Normal · criterio 2

- **Precondición:** Pantalla de revisión con una sugerencia.
- **Pasos:** Cambiar la categoría a Imagenología y el tipo a Radiografía de tórax → "Confirmar y guardar".
- **Resultado esperado:** Se guarda la corrección; en la lista y en la línea de tiempo el examen aparece como Radiografía de tórax.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-IAX-04.png`)

### CP-IAX-05 · Error de usuario · criterio 2

- **Precondición:** Pantalla de revisión.
- **Pasos:** Elegir una categoría y dejar el tipo vacío → "Confirmar y guardar".
- **Resultado esperado:** Aviso "Elige la categoría y el tipo del examen"; no se guarda.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-IAX-05.png`)

### CP-IAX-06 · Límite · criterio 2

- **Precondición:** Categoría "Otro".
- **Pasos:** Elegir Otro → escribir "Prueba de embarazo" → guardar.
- **Resultado esperado:** Se guarda con la categoría Otro y ese tipo.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-IAX-06.png`)

### CP-IAX-07 · Normal · criterio 3

- **Precondición:** Foto que no es un examen (por ejemplo, un paisaje).
- **Pasos:** Subir sin nombre.
- **Resultado esperado:** El examen se guarda igual ("Examen sin clasificar") y la revisión pide elegir la categoría y el tipo.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-IAX-07.png`)

### CP-IAX-08 · Límite · criterio 3

- **Precondición:** API sin `GEMINI_API_KEY` o sin conexión a Gemini.
- **Pasos:** Subir un examen.
- **Resultado esperado:** La carga termina igual en pocos segundos; queda sin clasificar y el paciente elige.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-IAX-08.png`)

### CP-IAX-09 · Error de usuario · criterio 3

- **Precondición:** Archivo de 12 MB o en formato .docx.
- **Pasos:** Intentar subirlo.
- **Resultado esperado:** "El archivo supera el máximo de 10 MB" o "Formato no permitido".
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-IAX-09.png`)

