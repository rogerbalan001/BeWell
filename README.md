# Bewell — MVP Sprint 1

Plataforma e-Health (Universidad Metropolitana · Ingeniería de Software · Sección 1).
Implementación del Producto Mínimo Viable siguiendo la arquitectura definida en el **Taller 1**:

| Capa | Tecnología | Arquitectura |
|---|---|---|
| Cliente (Android · iOS · Web) | Flutter 3 / Dart 3 | Clean Architecture por *feature*: Presentación (Cubit) → Dominio (entidades, casos de uso, repositorios abstractos) ← Datos (data sources, mappers, repositorios). Core: `get_it`, Dio con renovación de token, `flutter_secure_storage`, `go_router`. |
| API | NestJS 11 (TypeScript) | Monolito modular con arquitectura hexagonal interna: cada módulo tiene `interface/` «Boundary», `application/` «Control», `domain/` «Entity» + puertos «Repository», `infrastructure/` (Mongoose y adaptadores). |
| Datos | MongoDB 7 (+ Redis opcional) | Una colección por módulo, cifrado a nivel de campo (AES-256-GCM), dinero en `Decimal128`, índice único parcial contra doble reserva. |

```
bewell/
├── backend/            API NestJS (12 módulos de dominio + shared)
│   ├── src/modules/<módulo>/{interface,application,domain,infrastructure}
│   ├── src/seed/seed.ts       datos de demostración
│   └── test/                  76 pruebas (dominio + casos de uso con adaptadores en memoria)
├── app/                Flutter (lib/core + lib/features/<feature>/{data,domain,presentation})
├── docs/BACKLOG.md     historias de usuario de Trello → tareas técnicas (DoD)
├── docs/Bewell_Guia_Instalacion.pdf   guía de instalación paso a paso
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
npm test                              # 76 pruebas unitarias
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

> ⚠️ El código Flutter se escribió sin poder compilarse en el entorno de desarrollo (sin acceso a pub.dev). Ejecuta `flutter analyze` al instalarlo; si aparece algún error de compilación será puntual (nombre de parámetro o import) y se corrige en minutos.

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

Fuente: tablero Trello *BeWell* (15 HU). Detalle de tareas en [`docs/BACKLOG.md`](docs/BACKLOG.md).

| # | Historia (resumen) | Lista Trello | Estado en el MVP |
|---|---|---|---|
| 15 | Agendar consulta con el especialista eligiendo fecha y hora | Doing | ✅ Completa (disponibilidad, doble reserva imposible, confirmación) |
| 10 | Ser dueño de mi expediente y llevarlo de un médico a otro | To Do | ✅ Expediente único, médicos autorizados agregan información, **exportación PDF** |
| 11 | Validar título, colegiatura y cédula de cada médico | To Do | ✅ Carga, aprobación/rechazo con motivo, insignia "Médico verificado" |
| 12 | Reseñas solo de consultas atendidas | To Do | ✅ 4 criterios 1–5 + comentario, una por cita, editable 7 días |
| 13 | Referir pacientes a especialistas | To Do | ✅ Paciente aprueba, especialista recibe acceso + notificación y propone horarios |
| 14 | Cita de seguimiento aceptada por ambas partes | To Do | ✅ "Pendiente de aceptación", cancelación automática a las 48 h |
| 1 | Pagar en la app y liberar al médico después de la consulta | Backlog | ✅ Retención al reservar, liberación a las 24 h, disputa. Pasarela **simulada** (alcance del documento) |
| 2 | Perfiles de hijos o padres | Backlog | ✅ Selector de perfil, expediente independiente. *Traspaso a mayoría de edad: Sprint 2* |
| — | Historia clínica del paciente | — | ✅ Antecedentes estructurados (alergias, patológicos, quirúrgicos, medicamentos, familiares, hábitos, gineco-obstétricos) + historia de cada consulta (motivo, enfermedad actual, signos vitales con IMC, examen físico, impresión diagnóstica y plan), corrección en 24 h, exportación PDF |
| 3 | Línea de tiempo del paciente para el médico | Backlog | ✅ Orden cronológico inverso, filtros por tipo, detalle |
| 4 | Solicitar exámenes y recibir resultados | Backlog | ✅ Catálogo, orden "pendiente" → "completada", notificación al médico |
| 6 | Política de cancelación del médico | Backlog | ✅ Flexible / moderada / estricta, visible antes de confirmar, reembolso automático |
| 7 | Récipes con firma y código verificable | Backlog | ✅ ECDSA P-256 + JCS (RFC 8785), QR, verificación pública, guardado en expediente |
| 8 | QR de emergencia | Backlog | ✅ Sin sesión, solo la ficha, regeneración invalida el anterior, caché + auditoría |
| 9 | Decidir qué médico ve qué parte y por cuánto tiempo | Backlog | ✅ Permisos por sección con vencimiento, revocación inmediata, auditoría visible |
| 0 | Subir PDF/fotos y extraer valores | Backlog | 🟡 Carga JPG/PNG/PDF ≤ 10 MB, revisión y corrección, fallback a adjunto. **OCR simulado** (el documento lo ubica en sprints posteriores) |
| 5 | Recordatorios de citas y medicamentos | Backlog | ⏭️ Sprint 2 (la bandeja de notificaciones in-app ya existe) |

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
| Workers | Tareas programadas `@Cron`: liberar pagos a las 24 h y vencer propuestas a las 48 h |
| Flutter Clean Architecture + BLoC | `app/lib/features/*/{domain,data,presentation}`; `core/di/injector.dart` es la raíz de composición |

### Simplificaciones del MVP (documentadas)
- **Pasarela de pagos simulada** (`PasarelaSimuladaAdapter`) detrás del puerto `PasarelaPagos`.
- **OCR simulado** (`OCR_PROVIDER=simulado`): devuelve plantillas de analitos según el examen; un archivo con "ilegible" en el nombre simula un documento no reconocido.
- **Almacenamiento local cifrado** en lugar de S3 (mismo puerto).
- **KMS local** en lugar de un KMS gestionado (mismo puerto).
- Transacciones multi-documento: la doble reserva se impide con índice único parcial y el pago fallido se compensa cancelando la cita.

---

## 4. Guion sugerido para el Product Review (15 de octubre)
1. **Landing** → "Reservar cita" → registro / inicio de sesión (Sofía).
2. **Paso 1–3 de agendamiento**: directorio con filtros → horario y modalidad → confirmación con política y pago retenido.
3. **Mis citas** → detalle → simular cancelación (muestra el reembolso según la política).
4. **Médico (Ruiz)**: agenda de hoy → cita en curso → *Marcar como atendida* con nota y diagnóstico → *Emitir récipe* → *Solicitar exámenes*.
5. **Paciente**: récipe con QR → abrir `/#/verificar/<código>` sin sesión (farmacia). Reseñar la consulta. Subir resultados de la orden (OCR simulado) y corregir valores.
6. **Expediente**: línea de tiempo con filtros, exportar PDF, conceder/revocar acceso a la Dra. Soto, ver auditoría.
7. **Referencias**: aprobar la referencia a Cardiología → entrar como Dr. Campos y proponer horario → aceptar como Sofía.
8. **QR de emergencia**: abrir `/#/e/<token>` sin sesión (vista pública) y con `emergencia@bewell.app` (vista ampliada).
9. **Admin**: aprobar las credenciales de Andrés Pérez → aparece en el directorio con la insignia.
