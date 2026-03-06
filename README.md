# ArcoBot — Arquitectura Frontend (Flutter)

## Estado actual (implementado)

Se creó el primer flujo de autenticación con Logto siguiendo la arquitectura propuesta:

- `core/auth/logto_service.dart`: integración con `logto_dart_sdk`.
- `core/auth/auth_guard.dart`: guard de rutas por estado de autenticación.
- `core/network/api_client.dart`: `Dio` con interceptor `Bearer` leyendo token desde Logto SDK.
- `features/auth/data/auth_repository.dart`: capa de datos de auth.
- `features/auth/presentation/auth_provider.dart`: estado y acciones de auth (Riverpod).
- `features/auth/presentation/login_screen.dart`: pantalla de login.
- `core/config/router.dart` + `main.dart`: navegación protegida (`/login` y `/dashboard`).

> Nota: la sección de estructura amplia más abajo es el **roadmap objetivo**; actualmente solo está implementado el módulo inicial de auth/dashboard.

## Dependencias

```bash
flutter pub get
```

## Recursos visuales (imagenes)

Coloca tus imagenes en `assets/images/` usando las rutas definidas en:

- `assets/images/README.md`

## Variables de entorno (archivo local)

1. Copia `.env.example.json` a `.env.dev.json`.
2. Reemplaza los valores con tu tenant y app de Logto.
3. Ejecuta la app con:

```bash
flutter run --dart-define-from-file=.env.dev.json
```

## Ejecutar con variables de entorno

Ejemplo:

```bash
flutter run \
  --dart-define=LOGTO_ENDPOINT=https://TU_TENANT.logto.app \
  --dart-define=LOGTO_APP_ID=TU_APP_ID \
  --dart-define=LOGTO_AUDIENCE=https://api.arcobot \
  --dart-define=LOGTO_ORGANIZATION_ID=TU_ORG_ID \
  --dart-define=LOGTO_REDIRECT_URI=io.arcobot.app://callback \
  --dart-define=LOGTO_POST_LOGOUT_REDIRECT_URI=io.arcobot.app://logout-callback \
  --dart-define=LOGTO_SCOPES="openid profile email offline_access" \
  --dart-define=LOGTO_FACEBOOK_CONNECTOR_TARGET=facebook
```

`API_BASE_URL` es opcional y solo aplica cuando consumas API propia desde `core/network/api_client.dart`.
`LOGTO_REDIRECT_URI` y `LOGTO_POST_LOGOUT_REDIRECT_URI` también son opcionales:
- En mobile se usan por defecto `io.arcobot.app://callback` y `io.arcobot.app://logout-callback`.
- En web se usa por defecto `https://tu-dominio/callback.html` (detectado automáticamente con el origin actual).

## Setup Android, iOS y Web para Logto SDK

- `android/app/build.gradle.kts`:
  - configurar `applicationId/namespace` reales (no `com.example`).
  - para release, crear `android/key.properties` con keystore de producción.
- `android/app/src/main/AndroidManifest.xml`:
  - definir backup seguro y exclusión de `FlutterSecureStorage` con `@xml/backup_rules`.
  - registrar `com.linusu.flutter_web_auth_2.CallbackActivity` con scheme `io.arcobot.app`.
- `ios/Runner/Info.plist`:
  - registrar `CFBundleURLTypes` con scheme `io.arcobot.app`.
- `web/callback.html`: archivo agregado para cerrar el callback web con `postMessage`.

## Stack
- **Framework:** Flutter (iOS + Android + Web desde un solo código)
- **Estado:** Riverpod
- **Navegación:** GoRouter
- **HTTP:** Dio + interceptor JWT
- **Auth:** logto_dart_sdk

---

## Principio de arquitectura

Cada feature sigue la misma estructura de 3 capas:

```
data/          → repositorio, llamadas a la API
domain/        → modelos de datos
presentation/  → screens, widgets, providers (Riverpod)
```

Esto permite que cada feature sea independiente y escale sin enredarse con las demás.

---

## Estructura de carpetas

```
arcobot-app/
├── lib/
│   │
│   ├── core/                               # Código compartido por toda la app
│   │   ├── config/
│   │   │   ├── env.dart                    # Variables de entorno
│   │   │   └── router.dart                 # GoRouter — todas las rutas
│   │   │
│   │   ├── auth/
│   │   │   ├── logto_service.dart          # Login / logout con Logto
│   │   │   └── auth_guard.dart             # Protección de rutas por rol
│   │   │
│   │   ├── network/
│   │   │   └── api_client.dart             # Dio + interceptor JWT
│   │   │
│   │   ├── theme/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_typography.dart
│   │   │   └── app_theme.dart
│   │   │
│   │   ├── widgets/                        # Widgets reutilizables globales
│   │   │   ├── arco_button.dart
│   │   │   ├── arco_avatar.dart            # Personajes (Bussy, perrito, ratoncito)
│   │   │   └── arco_audio_player.dart      # Reproductor de narraciones
│   │   │
│   │   └── utils/
│   │       ├── responsive.dart             # Helpers mobile vs web
│   │       └── extensions.dart
│   │
│   ├── features/
│   │   │
│   │   ├── auth/                           # Onboarding y login
│   │   │   ├── data/
│   │   │   │   └── auth_repository.dart
│   │   │   └── presentation/
│   │   │       ├── login_screen.dart
│   │   │       └── auth_provider.dart
│   │   │
│   │   ├── dashboard/                      # Home según rol
│   │   │   └── presentation/
│   │   │       ├── superadmin_dashboard.dart
│   │   │       ├── admin_dashboard.dart
│   │   │       ├── teacher_dashboard.dart
│   │   │       └── student_dashboard.dart
│   │   │
│   │   ├── robot/                          # Gestión del robot físico
│   │   │   ├── data/
│   │   │   │   ├── robot_repository.dart
│   │   │   │   └── ble_service.dart        # Bluetooth (solo mobile)
│   │   │   ├── domain/
│   │   │   │   └── robot_model.dart
│   │   │   └── presentation/
│   │   │       ├── ble_pairing_screen.dart
│   │   │       ├── joystick_screen.dart
│   │   │       └── robot_provider.dart
│   │   │
│   │   ├── simulator/                      # Gemelo Digital 2D
│   │   │   ├── domain/
│   │   │   │   ├── board_model.dart        # Tablero 5x8
│   │   │   │   └── path_optimizer.dart     # Lógica de ruta óptima
│   │   │   └── presentation/
│   │   │       ├── board_widget.dart
│   │   │       ├── drag_drop_widget.dart
│   │   │       ├── ghost_path_widget.dart
│   │   │       └── simulator_screen.dart
│   │   │
│   │   ├── library/                        # Smart Library — cartillas y tags
│   │   │   ├── data/
│   │   │   │   └── library_repository.dart
│   │   │   ├── domain/
│   │   │   │   ├── cartilla_model.dart
│   │   │   │   └── tag_model.dart
│   │   │   └── presentation/
│   │   │       ├── library_screen.dart
│   │   │       ├── cartilla_detail_screen.dart
│   │   │       ├── tag_filter_widget.dart
│   │   │       └── library_provider.dart
│   │   │
│   │   ├── sessions/                       # Sesiones de aula
│   │   │   ├── data/
│   │   │   │   └── session_repository.dart
│   │   │   ├── domain/
│   │   │   │   └── session_model.dart
│   │   │   └── presentation/
│   │   │       ├── create_session_screen.dart
│   │   │       ├── active_session_screen.dart
│   │   │       ├── pin_entry_screen.dart   # Entrada PIN estudiantes
│   │   │       └── session_provider.dart
│   │   │
│   │   ├── analytics/                      # Reportes y progreso
│   │   │   ├── data/
│   │   │   │   └── analytics_repository.dart
│   │   │   └── presentation/
│   │   │       ├── performance_screen.dart
│   │   │       ├── report_screen.dart
│   │   │       └── analytics_provider.dart
│   │   │
│   │   ├── content_studio/                 # Creador de tableros y ejercicios
│   │   │   ├── domain/
│   │   │   │   └── exercise_model.dart     # Matriz 12 preguntas x 12 respuestas
│   │   │   └── presentation/
│   │   │       ├── board_editor_screen.dart
│   │   │       ├── miniarco_editor_screen.dart
│   │   │       └── studio_provider.dart
│   │   │
│   │   └── gamification/                   # Logros, medallas, misiones
│   │       ├── data/
│   │       │   └── gamification_repository.dart
│   │       ├── domain/
│   │       │   └── achievement_model.dart
│   │       └── presentation/
│   │           ├── achievements_screen.dart
│   │           └── gamification_provider.dart
│   │
│   └── main.dart
│
├── assets/
│   ├── images/
│   │   ├── characters/                     # Bussy, perrito, ratoncito (estados emocionales)
│   │   └── ui/                             # Iconos sin texto
│   ├── audio/                              # Fanfarrias y narraciones
│   └── animations/                         # Lottie (celebración, error, espera)
│
└── pubspec.yaml
```

---

## UI/UX — Principios de diseño

### Público objetivo

| Usuario | UI |
|---|---|
| Niños pre-lectores (3-6 años) | Sin texto, iconos + audio + animaciones |
| Niños mayores (7+) | Texto gradual |
| Docentes y admins | Dashboard estándar con texto y tablas |

### Reglas de la UI para niños

- **Textless UI:** cero texto, todo comunicado con iconos, colores y audio
- **Personajes:** Bussy el osito, el perrito de Bussy y el ratoncito reaccionan según el estado (celebran, se entristecen, se sorprenden)
- **Feedback inmediato:**
  - ✅ Éxito → fanfarria + animación Lottie celebrando
  - ❌ Error → sonido suave + personaje triste (nunca agresivo)
  - ⏳ Cargando → personaje animado, nunca un spinner genérico
- **Accesibilidad:** botones grandes, alto contraste, zonas de tap amplias
