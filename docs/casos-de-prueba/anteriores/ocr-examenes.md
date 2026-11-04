# Casos de prueba · Subir fotos o PDF de exámenes y extraer los valores

- **Historia de usuario:** [https://trello.com/c/JQwGb83o](https://trello.com/c/JQwGb83o)
- **Sprint:** Sprint 2
- **Responsables de los casos:** Roger
- **Precondición general:** Sesión de Sofía (`sofia.morales@bewell.app`). API con `OCR_PROVIDER=tesseract`.
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-OCR-01 | 1 | Normal | Se acepta. | ☐ Pasa ☐ Falla | |
| CP-OCR-02 | 1 | Límite | El primero se acepta; el segundo se rechaza por tamaño. | ☐ Pasa ☐ Falla | |
| CP-OCR-03 | 2 | Normal | Aparecen los valores detectados con su confianza; se pueden corregir antes de guardar. | ☐ Pasa ☐ Falla | |
| CP-OCR-04 | 3 | Normal | Se guarda como archivo adjunto. | ☐ Pasa ☐ Falla | |

## Detalle

### CP-OCR-01 · Normal · criterio 1

- **Precondición:** Foto JPG de un examen de 3 MB.
- **Pasos:** Subir examen.
- **Resultado esperado:** Se acepta.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-OCR-01.png`)

### CP-OCR-02 · Límite · criterio 1

- **Precondición:** PDF de 10 MB exactos y otro de 10,5 MB.
- **Pasos:** Subir ambos.
- **Resultado esperado:** El primero se acepta; el segundo se rechaza por tamaño.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-OCR-02.png`)

### CP-OCR-03 · Normal · criterio 2

- **Precondición:** Foto legible de un perfil lipídico.
- **Pasos:** Subir → revisar.
- **Resultado esperado:** Aparecen los valores detectados con su confianza; se pueden corregir antes de guardar.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-OCR-03.png`)

### CP-OCR-04 · Normal · criterio 3

- **Precondición:** Foto borrosa o PDF escaneado sin texto.
- **Pasos:** Subir.
- **Resultado esperado:** Se guarda como archivo adjunto.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-OCR-04.png`)

