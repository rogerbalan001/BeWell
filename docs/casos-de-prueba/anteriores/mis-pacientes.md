# Casos de prueba · Lista de pacientes que me autorizaron

- **Historia de usuario:** [https://trello.com/c/tesEkCUa](https://trello.com/c/tesEkCUa)
- **Sprint:** Fuera de sprint
- **Responsables de los casos:** Juan y Natalio
- **Precondición general:** Sesión de la Dra. Soto.
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-MPA-01 | 1 | Normal | Solo pacientes con permiso vigente. | ☐ Pasa ☐ Falla | |
| CP-MPA-02 | 1 | Límite | Sofía ya no aparece. | ☐ Pasa ☐ Falla | |
| CP-MPA-03 | 2 | Normal | Solo las secciones autorizadas. | ☐ Pasa ☐ Falla | |
| CP-MPA-04 | 3 | Normal | Aparece el acceso de la Dra. Soto. | ☐ Pasa ☐ Falla | |

## Detalle

### CP-MPA-01 · Normal · criterio 1

- **Precondición:** Mis pacientes.
- **Pasos:** Ver la lista.
- **Resultado esperado:** Solo pacientes con permiso vigente.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-MPA-01.png`)

### CP-MPA-02 · Límite · criterio 1

- **Precondición:** Sofía revoca el permiso.
- **Pasos:** Recargar Mis pacientes.
- **Resultado esperado:** Sofía ya no aparece.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-MPA-02.png`)

### CP-MPA-03 · Normal · criterio 2

- **Precondición:** Abrir a Sofía.
- **Pasos:** Ver el expediente.
- **Resultado esperado:** Solo las secciones autorizadas.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-MPA-03.png`)

### CP-MPA-04 · Normal · criterio 3

- **Precondición:** Después de abrirlo.
- **Pasos:** Entrar como Sofía → Médicos autorizados → auditoría.
- **Resultado esperado:** Aparece el acceso de la Dra. Soto.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-MPA-04.png`)

