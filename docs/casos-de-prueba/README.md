# Casos de prueba de BeWell

Cada criterio de aceptación tiene al menos un caso de prueba. Los casos cubren el flujo normal, los errores de usuario y los casos límite (DoD del Sprint 3).

## Cómo se ejecutan

1. Usar el MVP publicado (https://bewell-app.onrender.com) o el entorno local con los datos de demostración (`cd backend && npm run seed`). La contraseña de todas las cuentas de demostración es `Bewell2026!`.
2. Seguir los pasos del caso y anotar el **resultado obtenido**, la **fecha**, **quién lo ejecutó** y marcar **Pasa** o **Falla**.
3. Guardar la evidencia (captura o video corto) en la carpeta `evidencias/` con el ID del caso como nombre (`CP-CHAT-03.png`).
4. Si un caso falla, abrir una tarjeta en Trello con el ID del caso y enlazarla aquí.

## Plantilla

Si la plantilla del curso tiene otro formato, copiar estos campos a ella sin cambiar los IDs.

| Campo | Contenido |
|---|---|
| ID | `CP-<HU>-<nn>` |
| Criterio | Número del criterio de aceptación de la tarjeta |
| Tipo | Normal, Error de usuario o Límite |
| Precondición | Estado y sesión necesarios antes de empezar |
| Pasos | Acciones en orden |
| Resultado esperado | Lo que dice el criterio |
| Resultado obtenido | Lo que pasó al ejecutarlo |
| Fecha | Día de la ejecución |
| Ejecutado por | Integrante |
| Evidencia | Archivo en `evidencias/` |

## Índice

| Archivo | Historia de usuario | Sprint | Responsables | Casos |
|---|---|---|---|---|
| [sprint-3/pagos-paypal.md](sprint-3/pagos-paypal.md) | [Pagar en la app y liberar el dinero al médico después de la consulta](https://trello.com/c/3tuPraZT) | Sprint 3 | Juan y Marco | 10 |
| [sprint-3/recipes.md](sprint-3/recipes.md) | [Emitir récipes digitales con código verificable](https://trello.com/c/t8su8sqt) | Sprint 3 | Natalio | 8 |
| [sprint-3/ia-examenes.md](sprint-3/ia-examenes.md) | [Deducir la categoría y el tipo del examen al subirlo (Gemini)](https://trello.com/c/Q46PaNjV) | Sprint 3 | Juan y Miguel | 9 |
| [sprint-3/chat.md](sprint-3/chat.md) | [Chatear de forma privada con el médico de la cita](https://trello.com/c/TdcNb1Jm) | Sprint 3 | Roger y Samir | 9 |
| [sprint-3/interfaz.md](sprint-3/interfaz.md) | [Interfaz coherente: mismos colores, textos y componentes](https://trello.com/c/v51Gpv2v) | Sprint 3 | Erika y Marco | 7 |
| [anteriores/agendar-consulta.md](anteriores/agendar-consulta.md) | [Agendar una consulta con el especialista elegido](https://trello.com/c/tIViSw2p) | Sprint 1 | Roger y Juan | 5 |
| [anteriores/expediente-clinico.md](anteriores/expediente-clinico.md) | [Ser dueño del expediente y llevarlo de un médico a otro](https://trello.com/c/RjWbTmEU) | Sprint 1 | Marco y Natalio | 4 |
| [anteriores/validacion-medicos.md](anteriores/validacion-medicos.md) | [Validar título, colegiatura y cédula de cada médico](https://trello.com/c/m0iW5DC1) | Sprint 1 | Samir y Miguel | 4 |
| [anteriores/resenas.md](anteriores/resenas.md) | [Leer y dejar reseñas solo de consultas atendidas](https://trello.com/c/HuaGhf5d) | Sprint 1 | Marco y Natalio | 5 |
| [anteriores/referencias.md](anteriores/referencias.md) | [Referir pacientes a especialistas de la red](https://trello.com/c/sOqLjCtj) | Sprint 1 | Roger | 5 |
| [anteriores/consulta-seguimiento.md](anteriores/consulta-seguimiento.md) | [Consulta de seguimiento aceptada por ambas partes](https://trello.com/c/0zVqAZs2) | Sprint 1 | Juan | 5 |
| [anteriores/solicitar-examenes.md](anteriores/solicitar-examenes.md) | [Solicitar exámenes y recibir los resultados en el expediente](https://trello.com/c/nbuV01WE) | Sprint 2 | Miguel | 5 |
| [anteriores/recordatorios.md](anteriores/recordatorios.md) | [Recordatorios de citas, medicamentos y exámenes](https://trello.com/c/nGAwU33i) | Sprint 2 | Roger y Natalio | 4 |
| [anteriores/linea-tiempo.md](anteriores/linea-tiempo.md) | [Línea de tiempo del paciente para el médico](https://trello.com/c/NT1pP2u6) | Sprint 2 | Marco y Roger | 4 |
| [anteriores/politica-cancelacion.md](anteriores/politica-cancelacion.md) | [Política de cancelación del médico](https://trello.com/c/5h48SKkO) | Sprint 2 | Juan y Natalio | 5 |
| [anteriores/historia-clinica.md](anteriores/historia-clinica.md) | [Historia clínica completa del paciente](https://trello.com/c/lP5Xrde3) | Sprint 2 | Samir | 5 |
| [anteriores/qr-emergencia.md](anteriores/qr-emergencia.md) | [QR de emergencia con la ficha médica](https://trello.com/c/hduuAJJ9) | Sprint 2 | Miguel | 5 |
| [anteriores/ocr-examenes.md](anteriores/ocr-examenes.md) | [Subir fotos o PDF de exámenes y extraer los valores](https://trello.com/c/JQwGb83o) | Sprint 2 | Roger | 4 |
| [anteriores/cuenta-sesion.md](anteriores/cuenta-sesion.md) | [Crear cuenta como paciente o médico e iniciar sesión](https://trello.com/c/IS3Dd6iI) | Fuera de sprint | Juan y Miguel | 5 |
| [anteriores/directorio-medicos.md](anteriores/directorio-medicos.md) | [Buscar médicos y ver su perfil](https://trello.com/c/ToRAAFcJ) | Fuera de sprint | Juan y Samir | 4 |
| [anteriores/horario-modalidades.md](anteriores/horario-modalidades.md) | [Configurar horario semanal y modalidades](https://trello.com/c/JkFElhnQ) | Fuera de sprint | Juan y Samir | 4 |
| [anteriores/mis-citas.md](anteriores/mis-citas.md) | [Consultar y cancelar mis citas](https://trello.com/c/gwEFVWQC) | Fuera de sprint | Roger y Marco | 4 |
| [anteriores/agenda-medico.md](anteriores/agenda-medico.md) | [Ver la agenda y registrar el resultado de cada cita](https://trello.com/c/3l7pCkXb) | Fuera de sprint | Roger y Marco | 4 |
| [anteriores/mis-pacientes.md](anteriores/mis-pacientes.md) | [Lista de pacientes que me autorizaron](https://trello.com/c/tesEkCUa) | Fuera de sprint | Juan y Natalio | 4 |
| [anteriores/notificaciones.md](anteriores/notificaciones.md) | [Centro de notificaciones](https://trello.com/c/P9m2dhnH) | Fuera de sprint | Juan y Samir | 4 |
| [anteriores/auditoria-accesos.md](anteriores/auditoria-accesos.md) | [Ver quién consultó mi expediente](https://trello.com/c/Wa4C25gr) | Fuera de sprint | Juan y Natalio | 3 |
| [anteriores/ficha-emergencia.md](anteriores/ficha-emergencia.md) | [Completar la ficha de emergencia y elegir qué muestra el QR](https://trello.com/c/pIt44NCG) | Fuera de sprint | Roger y Samir | 4 |
| [anteriores/pagina-publica.md](anteriores/pagina-publica.md) | [Conocer BeWell antes de registrarme](https://trello.com/c/ZU0LNdbT) | Fuera de sprint | Miguel y Samir | 4 |

Total: 143 casos en 28 historias de usuario.
