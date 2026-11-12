# Casos de prueba · Pagar en la app y liberar el dinero al médico después de la consulta

- **Historia de usuario:** [https://trello.com/c/3tuPraZT](https://trello.com/c/3tuPraZT)
- **Sprint:** Sprint 3
- **Responsables de los casos:** Juan y Marco
- **Precondición general:** API con `PAGOS_PROVEEDOR=paypal` y credenciales sandbox. Cuenta *Personal* de prueba de PayPal Developer.
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-PAG-01 | 1 | Normal | PayPal devuelve a la cita: estado **Confirmada**, pago "Pago retenido (protegido)". El médico recibe "Nueva cita agendada" y el paciente "Pago recibido". | ☐ Pasa ☐ Falla | |
| CP-PAG-02 | 1 | Error de usuario | La cita queda **Pendiente de pago** con el aviso "Cancelaste el pago en PayPal"; se ven "Pagar con PayPal", "Ya pagué, verificar" y "Cancelar reserva". | ☐ Pasa ☐ Falla | |
| CP-PAG-03 | 1 | Límite | La reserva se cancela sola, el horario vuelve a estar libre y llega "Reserva liberada". No hay cobro en sandbox.paypal.com. | ☐ Pasa ☐ Falla | |
| CP-PAG-04 | 1 | Límite | La cita pasa a Confirmada sin pagar dos veces. | ☐ Pasa ☐ Falla | |
| CP-PAG-05 | 2 | Normal | El pago pasa a "Liberado al médico"; en sandbox.paypal.com (cuenta Business) aparece la captura. | ☐ Pasa ☐ Falla | |
| CP-PAG-06 | 3 | Normal | El pago queda "Retenido por reporte en revisión". El médico recibe "Un paciente reportó un problema" y el paciente "Recibimos tu reporte". | ☐ Pasa ☐ Falla | |
| CP-PAG-07 | 3 | Normal | La disputa desaparece de la lista. Paciente y médico reciben el aviso con la nota; en sandbox se ve el reembolso o la anulación. | ☐ Pasa ☐ Falla | |
| CP-PAG-08 | 3 | Error de usuario | No cambia nada: la disputa sigue en la lista. | ☐ Pasa ☐ Falla | |
| CP-PAG-09 | 3 | Límite | El botón ya no aparece (o la API responde que el plazo de 24 horas venció). | ☐ Pasa ☐ Falla | |
| CP-PAG-10 | 1 | Error de usuario | Se muestra el reembolso según la política; en sandbox se anula la retención o se cobra solo la penalización. | ☐ Pasa ☐ Falla | |

## Detalle

### CP-PAG-01 · Normal · criterio 1

- **Precondición:** Sesión de Sofía (`sofia.morales@bewell.app`, contraseña `Bewell2026!`). Médico con horario libre.
- **Pasos:** Directorio → elegir médico → horario → "Confirmar y pagar con PayPal" → iniciar sesión con la cuenta Personal de prueba → pagar.
- **Resultado esperado:** PayPal devuelve a la cita: estado **Confirmada**, pago "Pago retenido (protegido)". El médico recibe "Nueva cita agendada" y el paciente "Pago recibido".
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-PAG-01.png`)

### CP-PAG-02 · Error de usuario · criterio 1

- **Precondición:** Igual que el anterior.
- **Pasos:** En PayPal tocar "Cancelar y volver a Bewell".
- **Resultado esperado:** La cita queda **Pendiente de pago** con el aviso "Cancelaste el pago en PayPal"; se ven "Pagar con PayPal", "Ya pagué, verificar" y "Cancelar reserva".
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-PAG-02.png`)

### CP-PAG-03 · Límite · criterio 1

- **Precondición:** Reserva pendiente de pago.
- **Pasos:** No pagar y esperar 30 minutos (o más).
- **Resultado esperado:** La reserva se cancela sola, el horario vuelve a estar libre y llega "Reserva liberada". No hay cobro en sandbox.paypal.com.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-PAG-03.png`)

### CP-PAG-04 · Límite · criterio 1

- **Precondición:** Reserva pendiente; pagar en PayPal pero cerrar el navegador antes de volver.
- **Pasos:** Abrir la cita en la app → "Ya pagué, verificar".
- **Resultado esperado:** La cita pasa a Confirmada sin pagar dos veces.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-PAG-04.png`)

### CP-PAG-05 · Normal · criterio 2

- **Precondición:** Cita pagada y marcada como atendida por el médico (`mateo.ruiz@bewell.app`).
- **Pasos:** Esperar 24 h (o revisar en la base `liberarDespuesDe`) y abrir la cita.
- **Resultado esperado:** El pago pasa a "Liberado al médico"; en sandbox.paypal.com (cuenta Business) aparece la captura.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-PAG-05.png`)

### CP-PAG-06 · Normal · criterio 3

- **Precondición:** Cita atendida hace menos de 24 h. Sesión de Sofía (`sofia.morales@bewell.app`, contraseña `Bewell2026!`).
- **Pasos:** Detalle de la cita → "Reportar un problema" → escribir el motivo.
- **Resultado esperado:** El pago queda "Retenido por reporte en revisión". El médico recibe "Un paciente reportó un problema" y el paciente "Recibimos tu reporte".
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-PAG-06.png`)

### CP-PAG-07 · Normal · criterio 3

- **Precondición:** Disputa abierta. Sesión de `admin@bewell.app`.
- **Pasos:** Menú → Disputas → ver el motivo → "Reembolsar al paciente" → confirmar con una nota.
- **Resultado esperado:** La disputa desaparece de la lista. Paciente y médico reciben el aviso con la nota; en sandbox se ve el reembolso o la anulación.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-PAG-07.png`)

### CP-PAG-08 · Error de usuario · criterio 3

- **Precondición:** Disputa abierta. Sesión de admin.
- **Pasos:** "Liberar al médico" → en la confirmación tocar "Volver".
- **Resultado esperado:** No cambia nada: la disputa sigue en la lista.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-PAG-08.png`)

### CP-PAG-09 · Límite · criterio 3

- **Precondición:** Cita atendida hace más de 24 h.
- **Pasos:** Intentar "Reportar un problema".
- **Resultado esperado:** El botón ya no aparece (o la API responde que el plazo de 24 horas venció).
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-PAG-09.png`)

### CP-PAG-10 · Error de usuario · criterio 1

- **Precondición:** Cita confirmada y pagada, a más de 24 h de la consulta (política moderada).
- **Pasos:** "Cancelar cita" → motivo.
- **Resultado esperado:** Se muestra el reembolso según la política; en sandbox se anula la retención o se cobra solo la penalización.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-PAG-10.png`)

