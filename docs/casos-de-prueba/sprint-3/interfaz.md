# Casos de prueba · Interfaz coherente: mismos colores, textos y componentes

- **Historia de usuario:** [https://trello.com/c/v51Gpv2v](https://trello.com/c/v51Gpv2v)
- **Sprint:** Sprint 3
- **Responsables de los casos:** Erika y Marco
- **Precondición general:** App web y APK con el último main. Figma del proyecto abierto. Herramienta de contraste (por ejemplo, WebAIM Contrast Checker).
- **Entorno:** https://bewell-app.onrender.com (API https://bewell-api.onrender.com) o local con `npm run seed`.

## Resumen

| ID | Criterio | Tipo | Resultado esperado | Resultado | Fecha |
|---|---|---|---|---|---|
| CP-UI-01 | 1 | Normal | Los títulos de tarjeta, los textos secundarios y los detalles tienen el mismo tamaño, peso y color en los cuatro flujos. | ☐ Pasa ☐ Falla | |
| CP-UI-02 | 1 | Normal | Solo se usan colores del tema (azul primario, marino, pizarra, verde, ámbar, error); no hay grises ni blancos sueltos. | ☐ Pasa ☐ Falla | |
| CP-UI-03 | 2 | Normal | Los tres estados usan los mismos componentes y textos en los cuatro flujos. | ☐ Pasa ☐ Falla | |
| CP-UI-04 | 2 | Normal | Las diferencias quedan listadas y corregidas o justificadas. | ☐ Pasa ☐ Falla | |
| CP-UI-05 | 3 | Límite | Todo el texto llega a 4.5:1 o más (la prueba automática `tema_test.dart` lo verifica para la paleta). | ☐ Pasa ☐ Falla | |
| CP-UI-06 | 3 | Límite | El área táctil de cada botón es de al menos 48 × 48. | ☐ Pasa ☐ Falla | |
| CP-UI-07 | 3 | Error de usuario | El texto no se corta ni se superpone. | ☐ Pasa ☐ Falla | |

## Detalle

### CP-UI-01 · Normal · criterio 1

- **Precondición:** Flujos de reserva, expediente, exámenes y récipes.
- **Pasos:** Recorrer cada pantalla y comparar títulos, textos secundarios y fechas.
- **Resultado esperado:** Los títulos de tarjeta, los textos secundarios y los detalles tienen el mismo tamaño, peso y color en los cuatro flujos.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-UI-01.png`)

### CP-UI-02 · Normal · criterio 1

- **Precondición:** Mismas pantallas.
- **Pasos:** Revisar los colores de botones, chips de estado y fondos.
- **Resultado esperado:** Solo se usan colores del tema (azul primario, marino, pizarra, verde, ámbar, error); no hay grises ni blancos sueltos.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-UI-02.png`)

### CP-UI-03 · Normal · criterio 2

- **Precondición:** Una pantalla de cada flujo.
- **Pasos:** Ver el estado de carga, el vacío (por ejemplo, sin exámenes) y el de error (API apagada).
- **Resultado esperado:** Los tres estados usan los mismos componentes y textos en los cuatro flujos.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-UI-03.png`)

### CP-UI-04 · Normal · criterio 2

- **Precondición:** Figma.
- **Pasos:** Comparar cada pantalla con su diseño y anotar las diferencias.
- **Resultado esperado:** Las diferencias quedan listadas y corregidas o justificadas.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-UI-04.png`)

### CP-UI-05 · Límite · criterio 3

- **Precondición:** Chips de estado verdes, azules y ámbar; texto gris sobre fondos azules.
- **Pasos:** Medir el contraste.
- **Resultado esperado:** Todo el texto llega a 4.5:1 o más (la prueba automática `tema_test.dart` lo verifica para la paleta).
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-UI-05.png`)

### CP-UI-06 · Límite · criterio 3

- **Precondición:** Teléfono con el APK.
- **Pasos:** Medir los botones de icono, chips y botones de texto.
- **Resultado esperado:** El área táctil de cada botón es de al menos 48 × 48.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-UI-06.png`)

### CP-UI-07 · Error de usuario · criterio 3

- **Precondición:** Tamaño de letra del sistema al 200 %.
- **Pasos:** Recorrer los cuatro flujos.
- **Resultado esperado:** El texto no se corta ni se superpone.
- **Resultado obtenido:** 
- **Fecha de ejecución:** 
- **Ejecutado por:** 
- **Evidencia:** (captura o video en `evidencias/CP-UI-07.png`)

