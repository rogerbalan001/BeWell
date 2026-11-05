# Bewell — MVP (Sprint 3)

Plataforma e-Health (Universidad Metropolitana · Ingeniería de Software · Sección 1).
Implementación del Producto Mínimo Viable siguiendo la arquitectura definida en el **Taller 1**:

| Capa | Tecnología | Arquitectura |
|---|---|---|
| Cliente (Android · iOS · Web) | Flutter 3 / Dart 3 | Clean Architecture por *feature*: Presentación (Cubit) → Dominio (entidades, casos de uso, repositorios abstractos) ← Datos (data sources, mappers, repositorios). Core: `get_it`, Dio con renovación de token, `flutter_secure_storage`, `go_router`. |
| API | NestJS 11 (TypeScript) | Monolito modular con arquitectura hexagonal interna: cada módulo tiene `interface/` «Boundary», `application/` «Control», `domain/` «Entity» + puertos «Repository», `infrastructure/` (Mongoose y adaptadores). |
| Datos | MongoDB 7 (+ Redis opcional) | Una colección por módulo, cifrado a nivel de campo (AES-256-GCM), dinero en `Decimal128`, índice único parcial contra doble reserva. |

```
bewell/
├── backend/            API NestJS (16 módulos de dominio + shared)
│   ├── src/modules/<módulo>/{interface,application,domain,infrastructure}
│   ├── src/seed/seed.ts       datos de demostración
│   ├── scripts/medir-p95-qr.js   mide la latencia de la ficha QR
│   ├── test/                  pruebas unitarias y de casos de uso (adaptadores en memoria)
│   └── test/e2e/              pruebas de punta a punta por HTTP contra MongoDB
├── app/                Flutter (lib/core + lib/features/<feature>/{data,domain,presentation})
├── docs/casos-de-prueba/   casos de prueba por historia de usuario (se ejecutan en el MVP)
├── .github/            CI: pruebas, compilación web y APK de Android en cada push
└── docker-compose.yml  MongoDB + Redis (+ API)
```

---

## 1. Puesta en marcha

### Requisitos
Node.js 20+ · Flutter 3.22+ (Dart 3.4+) · Docker (o MongoDB 7 local).

### Backend
```bash
docker compose up -d mongo redis      # bases de datos
cd backend
npm install
npm run configurar                    # crea .env con llaves aleatorias (AES, KMS, JWT)
npm run seed                          # BORRA la BD y carga datos de demostración
npm run start:dev                     # http://localhost:3000/api/v1  ·  OpenAPI: http://localhost:3000/api/docs
npm test                              # pruebas unitarias y de casos de uso
npm run test:e2e                      # punta a punta por HTTP (necesita MongoDB en localhost:27017)
```
Para usar Redis como caché de la ficha QR, descomenta `REDIS_URL` en `.env`; sin él se usa caché en memoria.

### App Flutter
El repositorio incluye `lib/`, `test/` y `pubspec.yaml`. Genera las carpetas de plataforma una sola vez:
```bash
cd app
flutter create . --project-name bewell --platforms=web,android,ios
flutter pub get
flutter run -d chrome --web-port 8080          # recomendado para la demo
# Android (emulador): la URL por defecto es http://10.0.2.2:3000/api/v1
#   agrega android:usesCleartextTraffic="true" en <application> de AndroidManifest.xml (HTTP local)
# Otra URL de API: flutter run --dart-define=API_URL=https://mi-api/api/v1
```
`flutter create .` no sobrescribe los archivos existentes.

### En línea y en el teléfono
- **Web:** https://bewell-app.onrender.com · **API:** https://bewell-api.onrender.com/api/v1 (el plan gratuito de Render se duerme: la primera petición tarda ~50 s).
- **APK de Android:** GitHub Actions lo compila en cada cambio de `app/` y lo publica en la rama `apk-dist` (`Bewell.apk`).
- **CI:** en cada push a `main` y en cada pull request se tipa, se prueba (unitarias, e2e contra MongoDB y Flutter) y se compila. Los registros quedan en las ramas `ci-logs-backend` y `ci-logs-app`.

### Cuentas de demostración (contraseña `Bewell2026!`)
| Rol | Correo | Qué mostrar |
|---|---|---|
| Paciente titular (2 dependientes) | `sofia.morales@bewell.app` | Directorio → agendar → pagar; expediente; permisos; QR; exámenes; récipe; referencia pendiente |
| Paciente | `martin.alvarez@bewell.app` | Autor de las reseñas verificadas |
| Médico — Medicina General | `mateo.ruiz@bewell.app` | Cita que **empezó hace 10 min** lista para "Marcar como atendida", récipe, orden de exámenes |
| Médico — Medicina Interna / Cardiología / Pediatría | `valentina.soto@` · `daniel.campos@` · `camila.morales@bewell.app` | Agenda, referencias recibidas (Campos) |
| Médico **pendiente** de verificación | `andres.perez@bewell.app` | Perfil no público hasta aprobación |
| Administrador | `admin@bewell.app` | Aprobar / rechazar credenciales de Andrés Pérez |
| Personal de emergencia | `emergencia@bewell.app` | Ficha QR ampliada |

El seed imprime el **código del récipe** y la **URL del QR** de Sofía para probar las vistas públicas `/#/verificar/<código>` y `/#/e/<token>`.

---

## 2. Historias de usuario cubiertas

Fuente: tablero Trello *BeWell*. Las tareas técnicas de cada HU, con su responsable, están en su tarjeta.

| # | Historia (resumen) | Lista Trello | Estado en el MVP |
|---|---|---|---|
| 15 | Agendar consulta con el especialista eligiendo fecha y hora | Doing | ✅ Completa (disponibilidad, doble reserva imposible, confirmación) |
| 10 | Ser dueño de mi expediente y llevarlo de un médico a otro | To Do | ✅ Expediente único, médicos autorizados agregan información, **exportación PDF** |
| 11 | Validar título, colegiatura y cédula de cada médico | To Do | ✅ Carga, aprobación/rechazo con motivo, insignia "Médico verificado" |
| 12 | Reseñas solo de consultas atendidas | To Do | ✅ 4 criterios 1–5 + comentario, una por cita, editable 7 días |
| 13 | Referir pacientes a especialistas | To Do | ✅ Paciente aprueba, especialista recibe acceso + notificación y propone horarios |
| 14 | Cita de seguimiento aceptada por ambas partes | To Do | ✅ "Pendiente de aceptación", cancelación automática a las 48 h |
| 1 | Pagar en la app y liberar al médico después de la consulta | Sprint 3 | ✅ **PayPal sandbox** con retención al reservar, captura 24 h después de la consulta, disputas que el administrador resuelve (liberar o reembolsar) con aviso a ambas partes |
| 2 | Perfiles de hijos o padres | Backlog | 🟡 Selector de perfil, expediente independiente. Falta el traspaso al cumplir la mayoría de edad |
| — | Historia clínica del paciente | — | ✅ Antecedentes estructurados (alergias, patológicos, quirúrgicos, medicamentos, familiares, hábitos, gineco-obstétricos) + historia de cada consulta (motivo, enfermedad actual, signos vitales con IMC, examen físico, impresión diagnóstica y plan), corrección en 24 h, exportación PDF |
| 3 | Línea de tiempo del paciente para el médico | Backlog | ✅ Orden cronológico inverso, filtros por tipo, detalle |
| 4 | Solicitar exámenes y recibir resultados | Backlog | ✅ Catálogo, orden "pendiente" → "completada", notificación al médico |
| 6 | Política de cancelación del médico | Backlog | ✅ Flexible / moderada / estricta, visible antes de confirmar, reembolso automático |
| 7 | Récipes digitales con código verificable | Sprint 3 | ✅ Firma ECDSA P-256 + JCS (RFC 8785) que respalda el código, QR, verificación pública (válido, anulado, vencido, inexistente), guardado en expediente |
| 8 | QR de emergencia | Backlog | ✅ Sin sesión, solo la ficha, regeneración invalida el anterior, caché + auditoría |
| 9 | Decidir qué médico ve qué parte y por cuánto tiempo | Backlog | ✅ Permisos por sección con vencimiento, revocación inmediata, auditoría visible. Los antecedentes solo llegan a quien tiene la sección Diagnósticos |
| 0 | Subir PDF/fotos y extraer valores | Sprint 2 | ✅ Carga JPG/PNG/PDF ≤ 10 MB, **OCR real** (Tesseract para fotos, texto incrustado para PDF), revisión y corrección, fallback a adjunto |
| 5 | Recordatorios de citas, medicamentos y exámenes | Sprint 2 | ✅ Citas 24 h y 1 h antes, cada toma del récipe, órdenes pendientes a 1, 3 y 7 días; el paciente activa o desactiva cada tipo. Se envían a la bandeja in-app (push: Backlog) |
| — | Categoría y tipo de examen deducidos por IA | Sprint 3 | ✅ **Google Gemini** sugiere categoría, tipo y confianza al subir; el nombre es opcional; el paciente corrige la sugerencia o elige si la IA falla (el examen se guarda igual). Ver la sección 6 |
| — | Chat privado con el médico de la cita | Sprint 3 | ✅ Con cita confirmada o atendida, solo esas dos partes; se actualiza cada 5 s; notificación y contador de no leídos; mensajes cifrados |
| — | Interfaz coherente | Sprint 3 | ✅ Estilos de texto del tema y colores del tema en reserva, expediente, exámenes y récipes |

---

## 3. Cómo se cumple la arquitectura del Taller 1

| Decisión del documento | Dónde está en el código |
|---|---|
| Estereotipos «Boundary» / «Control» / «Entity» / «Repository» | `*.controller.ts`, guards y adapters → `interface/`; `*.service.ts` → `application/`; entidades con reglas → `domain/*.ts`; repositorios abstractos en `domain/`, implementación Mongoose en `infrastructure/` |
| Regla de dependencia (el dominio no conoce Nest ni Mongo) | `domain/` solo importa `shared/domain`. Las pruebas ejecutan los casos de uso con adaptadores en memoria (`backend/test/support`) |
| D3/D4 eventos y permisos en colecciones propias | `eventos_clinicos`, `permisos_acceso` (`modules/expediente`) |
| D5 caché de la ficha QR | Puerto `FichaEmergenciaCache` → Redis (`REDIS_URL`) o memoria |
| D6 URL prefirmadas | `AlmacenamientoArchivos.generarUrlLectura()` (HMAC + vencimiento) + `GET /archivos/:token` |
| D7 copia de la política en la cita | `Cita.politicaAplicada`, `Cita.cancelar()` devuelve el reembolso |
| D8 dinero en Decimal128 | Centavos en dominio ↔ `Decimal128` en Mongo (`mongo.utils.ts`) |
| D9 cifrado a nivel de campo | `AesGcmCifradorCampos` (antecedentes, resúmenes, motivos, ficha, récipes, resultados, cédula + HMAC) |
| D10 firma con llaves en KMS | Puerto `Kms` → `LocalKmsAdapter` (llave ECDSA por médico envuelta con `KMS_MASTER_KEY`) |
| Argon2id, JWT sin estado, RBAC | `Argon2PasswordHasher`, `JwtEmisorTokens` (acceso 15 min + refresh revocable), `JwtAuthGuard` + `RolesGuard` globales |
| Auditoría de solo inserción | Módulo `auditoria`; el paciente la ve en "Médicos autorizados" |
| Límites de tasa | `@nestjs/throttler` (más estricto en login, QR y verificación de récipes) |
| OpenAPI /api/v1 | Swagger en `/api/docs` |
| Workers | Tareas programadas `@Cron`: liberar pagos a las 24 h, vencer propuestas a las 48 h y liberar reservas sin pagar a los 30 min |
| Flutter Clean Architecture + BLoC | `app/lib/features/*/{domain,data,presentation}`; `core/di/injector.dart` es la raíz de composición |

### Simplificaciones del MVP (documentadas)
- **IA de exámenes** (`IA_EXAMENES`): `gemini` usa Google Gemini (`ClasificadorGeminiAdapter`); `simulado` deduce el tipo por los analitos que leyó el OCR y por el nombre del archivo, sin IA; `ninguno` deja que el paciente elija siempre. Detrás del puerto `ClasificadorExamen`.
- **Pagos** (`PAGOS_PROVEEDOR`): `paypal` usa **PayPal sandbox** (`PasarelaPayPalAdapter`, API REST v2) y `simulada` aprueba todo sin dinero real (`PasarelaSimuladaAdapter`), ambos detrás del puerto `PasarelaPagos`. Los datos de demostración siempre usan pagos simulados. Ver la sección 5.
- **OCR** (`OCR_PROVIDER`): `tesseract` lee fotos con Tesseract (español) y el texto de los PDF digitales, y reconoce 18 analitos comunes (`extractor-analitos.ts`). `simulado` devuelve plantillas de demo (un archivo con "ilegible" en el nombre simula un documento no reconocido). Un PDF escaneado sin texto queda como adjunto.
- **Almacenamiento local cifrado** en lugar de S3 (mismo puerto).
- **KMS local** en lugar de un KMS gestionado (mismo puerto).
- Transacciones multi-documento: la doble reserva se impide con índice único parcial y el pago fallido se compensa cancelando la cita.

---

## 4. Guion sugerido para el Product Review

**Novedades del Sprint 3** (además del recorrido de abajo):
1. **Pago con PayPal** (Sofía): reservar → "Confirmar y pagar con PayPal" → pagar con la cuenta *Personal* de prueba → la cita vuelve confirmada.
2. **Disputa** (Sofía en una cita atendida → "Reportar un problema") → **admin** → *Disputas* → reembolsar o liberar; ambos reciben el aviso.
3. **IA de exámenes**: subir un examen sin escribir el nombre → la app sugiere categoría y tipo con su confianza → corregirla.
4. **Chat**: Sofía escribe desde el detalle de su cita con la Dra. Soto → entrar como `valentina.soto@bewell.app` → aparece el contador y el mensaje (en máximo 5 s).

**Recorrido base:**
1. **Landing** → "Reservar cita" → registro / inicio de sesión (Sofía).
2. **Paso 1–3 de agendamiento**: directorio con filtros → horario y modalidad → confirmación con política y pago retenido.
3. **Mis citas** → detalle → simular cancelación (muestra el reembolso según la política).
4. **Médico (Ruiz)**: agenda de hoy → cita en curso → *Marcar como atendida* con nota y diagnóstico → *Emitir récipe* → *Solicitar exámenes*.
5. **Paciente**: récipe con QR → abrir `/#/verificar/<código>` sin sesión (farmacia). Reseñar la consulta. Subir resultados de la orden (foto o PDF; el OCR propone los valores) y corregirlos.
6. **Expediente**: línea de tiempo con filtros, exportar PDF, conceder/revocar acceso a la Dra. Soto, ver auditoría.
7. **Referencias**: aprobar la referencia a Cardiología → entrar como Dr. Campos y proponer horario → aceptar como Sofía.
8. **QR de emergencia**: abrir `/#/e/<token>` sin sesión (vista pública) y con `emergencia@bewell.app` (vista ampliada).
9. **Admin**: aprobar las credenciales de Andrés Pérez → aparece en el directorio con la insignia.

---

## 5. Pagos con PayPal (sandbox)

El paciente paga al reservar y el dinero queda **retenido** hasta 24 h después de la consulta (igual que con la pasarela simulada):

1. Al confirmar la cita, la API crea una orden de PayPal (`intent: AUTHORIZE`) y la cita queda **pendiente de pago**. La app abre PayPal.
2. El paciente inicia sesión con una **cuenta personal de prueba** y aprueba el pago. PayPal lo devuelve a `GET /api/v1/pagos/paypal/retorno`, que autoriza la orden (el monto queda retenido) y **confirma la cita**; luego redirige a la cita en la app web.
3. Si el paciente no vuelve a Bewell, el botón **"Ya pagué, verificar"** (`POST /citas/:id/pago/verificar`) revisa la orden en PayPal. Si no aprueba en **30 minutos**, la reserva se cancela y el horario se libera (no se cobra nada).
4. Cancelación antes de la consulta: se **anula** la retención (reembolso total) o se captura solo la penalización de la política.
5. 24 h después de la consulta (sin disputa) se **captura** la retención y el dinero pasa a la cuenta de PayPal de la plataforma.

**Configurar el sandbox**
1. Entra a [developer.paypal.com](https://developer.paypal.com) con una cuenta de PayPal → **Apps & Credentials** → pestaña **Sandbox** → *Create App* (tipo *Merchant*). Copia el **Client ID** y el **Secret**.
2. En **Testing Tools → Sandbox Accounts** hay una cuenta *Business* (recibe los pagos) y una *Personal* (el paciente). Con la *Personal* se paga en la app; su correo y contraseña de prueba se ven en *View/Edit account*.
3. En Render (bewell-api → Environment) o en `backend/.env`: `PAGOS_PROVEEDOR=paypal`, `PAYPAL_ENTORNO=sandbox`, `PAYPAL_CLIENT_ID=…`, `PAYPAL_CLIENT_SECRET=…`. `PUBLIC_API_URL` y `PUBLIC_WEB_URL` deben ser las URL públicas (PayPal redirige ahí).
4. Los movimientos se ven en [sandbox.paypal.com](https://www.sandbox.paypal.com) entrando con la cuenta *Business*.

Las tarifas de los médicos están en USD, que PayPal sandbox acepta. Sin credenciales, deja `PAGOS_PROVEEDOR=simulada`.

---

## 6. Categoría y tipo de examen con Google Gemini

Al subir una foto o un PDF, la API envía el archivo a **Gemini** junto con el catálogo de exámenes de Bewell y pide una respuesta JSON con **categoría**, **tipo** y **confianza** (0–1). Con confianza menor a 0,35 no se sugiere nada.

- Si el paciente no escribió el nombre, el examen se llama como el tipo sugerido.
- El paciente ve la sugerencia ("Sugerido por la app · 92 %") en la pantalla de revisión y puede corregirla (`PUT /examenes/:id/clasificacion`).
- Si Gemini falla, tarda más de 20 s o no reconoce el documento, el examen **se guarda igual** y el paciente elige la categoría y el tipo.

**Configurar:** crea una clave en [Google AI Studio](https://aistudio.google.com/app/apikey) y en Render (bewell-api → Environment) agrega `IA_EXAMENES=gemini` y `GEMINI_API_KEY=…` (opcional `GEMINI_MODELO`, por defecto `gemini-2.5-flash`). Sin clave, deja `IA_EXAMENES=simulado`.

> **Privacidad:** el documento del examen sale hacia Google para clasificarlo. En el plan gratuito de la API de Gemini, Google puede usar el contenido para mejorar sus productos; para datos reales de pacientes usa un proyecto con facturación activa (plan de pago), donde no se usa para entrenamiento, y avisa al paciente en los términos de uso.
