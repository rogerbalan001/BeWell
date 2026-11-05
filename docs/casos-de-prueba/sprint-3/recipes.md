# Casos de prueba · Emitir récipes digitales con código verificable

- **Historia de usuario:** [https://trello.com/c/t8su8sqt](https://trello.com/c/t8su8sqt)
- **Sprint:** Sprint 3
- **Responsables de los casos:** Natalio
- **Precondición general:** Sesión del Dr. Ruiz (`mateo.ruiz@bewell.app`) con una consulta atendida.
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-REC-01 | 1 | Normal | El récipe muestra médico, paciente, medicamentos, dosis, código RX-XXXXX-XXXXX y QR. Detrás, la firma digital del médico. | ☐ Pasa ☐ Falla | |
| CP-REC-02 | 1 | Error de usuario | No se permite: el récipe solo se emite para consultas atendidas. | ☐ Pasa ☐ Falla | |
| CP-REC-03 | 1 | Error de usuario | El formulario no deja continuar y pide completar los datos. | ☐ Pasa ☐ Falla | |
| CP-REC-04 | 2 | Normal | "Récipe válido" con emisor, paciente y medicamentos. | ☐ Pasa ☐ Falla | |
| CP-REC-05 | 2 | Normal | "Récipe NO válido" con "El médico anuló este récipe: <motivo>". | ☐ Pasa ☐ Falla | |
| CP-REC-06 | 2 | Límite | "Récipe NO válido" con "El récipe está vencido." | ☐ Pasa ☐ Falla | |
| CP-REC-07 | 2 | Error de usuario | Inventado: "No existe un récipe con ese código. No lo despache." Con minúsculas o espacios se normaliza y verifica igual. | ☐ Pasa ☐ Falla | |
| CP-REC-08 | 3 | Normal | Aparece el evento del récipe; desde el detalle "Ver récipe" abre la pantalla de récipes. | ☐ Pasa ☐ Falla | |

## Detalle

### CP-REC-01 · Normal · criterio 1

- **Precondición:** Consulta atendida.
- **Pasos:** Detalle de la cita → "Emitir récipe" → agregar medicamento, dosis y frecuencia → emitir.
- **Resultado esperado:** El récipe muestra médico, paciente, medicamentos, dosis, código RX-XXXXX-XXXXX y QR. Detrás, la firma digital del médico.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-REC-01.png`)

### CP-REC-02 · Error de usuario · criterio 1

- **Precondición:** Consulta todavía confirmada (no atendida).
- **Pasos:** Intentar emitir un récipe.
- **Resultado esperado:** No se permite: el récipe solo se emite para consultas atendidas.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-REC-02.png`)

### CP-REC-03 · Error de usuario · criterio 1

- **Precondición:** Formulario de emisión abierto.
- **Pasos:** Intentar emitir sin medicamentos o sin dosis.
- **Resultado esperado:** El formulario no deja continuar y pide completar los datos.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-REC-03.png`)

### CP-REC-04 · Normal · criterio 2

- **Precondición:** Récipe emitido. Navegador sin sesión.
- **Pasos:** Abrir `/#/verificar` → escribir el código → Verificar (o escanear el QR).
- **Resultado esperado:** "Récipe válido" con emisor, paciente y medicamentos.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-REC-04.png`)

### CP-REC-05 · Normal · criterio 2

- **Precondición:** Récipe anulado por el médico con motivo.
- **Pasos:** Verificar el código.
- **Resultado esperado:** "Récipe NO válido" con "El médico anuló este récipe: <motivo>".
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-REC-05.png`)

### CP-REC-06 · Límite · criterio 2

- **Precondición:** Récipe emitido por la API (`POST /recipes` con `validoDias: 1`, porque la app solo ofrece de 7 a 90 días) y verificado después de vencer.
- **Pasos:** Verificar el código.
- **Resultado esperado:** "Récipe NO válido" con "El récipe está vencido."
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-REC-06.png`)

### CP-REC-07 · Error de usuario · criterio 2

- **Precondición:** Navegador sin sesión.
- **Pasos:** Verificar un código inventado (RX-AAAAA-BBBBB) o con minúsculas y espacios.
- **Resultado esperado:** Inventado: "No existe un récipe con ese código. No lo despache." Con minúsculas o espacios se normaliza y verifica igual.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-REC-07.png`)

### CP-REC-08 · Normal · criterio 3

- **Precondición:** Récipe emitido para Sofía.
- **Pasos:** Entrar como Sofía → Expediente → línea de tiempo.
- **Resultado esperado:** Aparece el evento del récipe; desde el detalle "Ver récipe" abre la pantalla de récipes.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-REC-08.png`)

