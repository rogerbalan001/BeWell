# Casos de prueba · Validar título, colegiatura y cédula de cada médico

- **Historia de usuario:** [https://trello.com/c/m0iW5DC1](https://trello.com/c/m0iW5DC1)
- **Sprint:** Sprint 1
- **Responsables de los casos:** Samir y Miguel
- **Precondición general:** Médico pendiente `andres.perez@bewell.app`.
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-VAL-01 | 1 | Normal | Las tres quedan "En revisión"; su perfil todavía no es público. | ☐ Pasa ☐ Falla | |
| CP-VAL-02 | 1 | Error de usuario | Se rechaza con un mensaje claro. | ☐ Pasa ☐ Falla | |
| CP-VAL-03 | 2 | Normal | El médico recibe la notificación con el motivo del rechazo. | ☐ Pasa ☐ Falla | |
| CP-VAL-04 | 3 | Normal | Aparece con la insignia "Médico verificado". | ☐ Pasa ☐ Falla | |

## Detalle

### CP-VAL-01 · Normal · criterio 1

- **Precondición:** Sesión de Andrés Pérez.
- **Pasos:** Credenciales → subir título, colegiatura y cédula.
- **Resultado esperado:** Las tres quedan "En revisión"; su perfil todavía no es público.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-VAL-01.png`)

### CP-VAL-02 · Error de usuario · criterio 1

- **Precondición:** Sesión de Andrés Pérez.
- **Pasos:** Subir un archivo de más de 10 MB o en formato no permitido.
- **Resultado esperado:** Se rechaza con un mensaje claro.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-VAL-02.png`)

### CP-VAL-03 · Normal · criterio 2

- **Precondición:** Sesión de `admin@bewell.app`.
- **Pasos:** Verificaciones → ver documento → aprobar dos y rechazar uno con motivo.
- **Resultado esperado:** El médico recibe la notificación con el motivo del rechazo.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-VAL-03.png`)

### CP-VAL-04 · Normal · criterio 3

- **Precondición:** Las tres credenciales aprobadas.
- **Pasos:** Buscar a Andrés Pérez en el directorio.
- **Resultado esperado:** Aparece con la insignia "Médico verificado".
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-VAL-04.png`)

