# Mini Arco y Arcobot
## Arquitectura UX/UI infantil para Flutter

Fecha: 2026-03-06  
Versión: 1.0

---

## 0) Principios rectores del producto

1. Entender sin leer: la experiencia se comprende con iconos, color, audio y animación.
2. Un paso por vez: cada pantalla tiene una acción principal muy clara.
3. Feedback inmediato: toda acción del niño responde en menos de 300 ms con señal visual y sonora.
4. Frustración mínima: nunca hay pantallas de error secas; siempre hay ayuda de Arcobot.
5. Aprendizaje jugable: el progreso educativo se presenta como aventura, no como examen.

---

## 1) Concepto creativo: universo Mini Arco + personaje Arcobot

### Universo Mini Arco
Mini Arco es una ciudad-mundo flotante compuesta por islas temáticas educativas:

1. Isla Letras: lenguaje, fonética, vocabulario.
2. Isla Números: conteo, lógica, patrones.
3. Isla Ciencia: exploración, causa-efecto, curiosidad.
4. Isla Arte: creatividad, color, música.
5. Isla Retos: mezcla de habilidades en minijuegos.

Narrativa base:
- Arcobot necesita energía de aprendizaje para mantener encendido Mini Arco.
- Cada actividad completada entrega "chispas" que iluminan partes del mundo.
- El niño no "gana puntos", ayuda a construir y dar vida a Mini Arco.

### Arcobot (guía principal)

Rol:
- Tutor emocional + guía de interacción + celebrador del logro.

Personalidad:
- Curioso, paciente, juguetón, jamás juzga.

Estados de Arcobot (visual + voz):
1. Neutral atento: espera acción.
2. Entusiasta: celebra acierto.
3. Mentor: explica siguiente paso.
4. Acompañante: calma tras error.
5. Fiesta: recompensa o nivel completado.

Regla de comportamiento:
- Arcobot habla en frases de 2 a 6 palabras.
- Usa verbos de acción simples: "Toca", "Arrastra", "Busca", "Prueba".
- Evita términos técnicos o abstractos.

---

## 2) Identidad visual completa

### Estilo gráfico

Dirección visual:
- Ilustración 2.5D suave, bordes redondeados, sombras blandas.
- Formas orgánicas y amigables (evitar ángulos agresivos).
- Microdetalles vivos: estrellitas, chispas, partículas suaves.

Lenguaje visual:
- Todo elemento importante tiene volumen o halo para destacar.
- Fondos con profundidad por capas (cielo, nubes, formas abstractas).
- Iconografía gruesa y simple, legible en 24-32 px.

Emociones buscadas:
1. Seguridad: colores cálidos equilibrados.
2. Alegría: motion y feedback celebratorio.
3. Curiosidad: elementos que invitan a tocar.
4. Orgullo: recompensas visibles y acumulables.

---

## 3) Paleta de colores infantil profesional

### Paleta principal

1. Turquesa guía `#19BFB7`  
Uso: botones principales, progreso, foco positivo.

2. Azul cielo `#3A86FF`  
Uso: navegación, títulos, estados informativos.

3. Amarillo sol `#FFCB47`  
Uso: recompensas, estrellas, avisos positivos.

4. Coral suave `#FF6B6B`  
Uso: energía, énfasis lúdico, errores no críticos.

5. Verde logro `#55C271`  
Uso: confirmaciones, éxito.

6. Lila juego `#A78BFA`  
Uso: elementos de fantasía y mundos especiales.

### Neutros

1. Fondo nube `#F7FBFF`
2. Superficie `#FFFFFF`
3. Texto principal `#1F2A37`
4. Texto secundario `#4B5563`
5. Borde suave `#DDE7F0`

### Justificación psicológica

1. Azul + turquesa transmiten seguridad y guía.
2. Amarillo eleva sensación de premio y descubrimiento.
3. Coral dosificado introduce emoción sin agresividad.
4. Verde refuerza aprendizaje correcto y calma.
5. Fondos claros reducen fatiga cognitiva.

---

## 4) Tipografía y jerarquía visual

### Tipografías recomendadas (Flutter + Google Fonts)

1. Primaria UI: `Nunito` (alta legibilidad infantil).
2. Display/títulos: `Baloo 2` (carácter lúdico, amable).
3. Alternativa si se necesita una sola familia: `Nunito`.

### Escala tipográfica sugerida

1. `Display` (pantallas clave): 36, weight 800, line-height 1.1
2. `H1`: 28, weight 800
3. `H2`: 24, weight 700
4. `H3`: 20, weight 700
5. `Body`: 18, weight 600
6. `Body small`: 16, weight 600
7. `Label botón`: 18, weight 800

Reglas:
- Para primeros lectores, usar mínimo 16.
- Máximo dos estilos de texto por bloque.
- Priorizar mensajes de 2 a 5 palabras.

---

## 5) Sistema completo de componentes UI

### Tokens base

1. Radio base: 20
2. Radio tarjetas grandes: 28
3. Espaciado: 4, 8, 12, 16, 20, 24, 32
4. Altura botón principal: 64
5. Tamaño objetivo táctil mínimo: 56x56

### Componentes clave

1. Botón Primario
- Fondo turquesa, texto blanco, sombra suave, icono opcional.
- Estados: normal, presionado, deshabilitado, cargando.

2. Botón Secundario
- Fondo blanco, borde color, texto color.

3. Botón Ícono redondo
- Diámetro 56, icono 24-28.
- Uso: retroceso, audio, ayuda.

4. Tarjeta Mundo
- Imagen grande arriba, nombre corto, progreso visible.
- Estado bloqueado: overlay suave + candado grande.

5. Tarjeta Actividad
- Ilustración, dificultad por caritas/estrellas, duración estimada (icono reloj).

6. Barra de progreso lúdica
- Forma de tubo energético con partículas al avanzar.

7. Indicador de vidas/intentos
- No usar corazones que penalicen duro.
- Usar "burbujas de intento" con recarga por ayuda.

8. Recompensas
- Chips de "chispas", "estrellas", "stickers".
- Animación de entrada con escala + brillo.

9. Navegación inferior
- Máx 4 tabs: Inicio, Mundos, Premios, Perfil.
- Icono + texto corto.

10. Globo de Arcobot
- Componente fijo reutilizable con avatar + texto + botón de audio.
- Posición recomendada: esquina inferior izquierda en juego, superior en flujos guiados.

---

## 6) Diseño detallado de pantallas principales

## 6.1 Splash Screen

Objetivo:
- Cargar app y establecer tono emocional.

Contenido:
1. Fondo degradado con formas suaves.
2. Lottie de Arcobot al centro (1 sola reproducción).
3. Texto corto: "Cargando..."

Wireframe:
```text
┌──────────────────────────────┐
│        cielo degradado       │
│                              │
│           [LOTTIE]           │
│          Arcobot intro       │
│                              │
│          Cargando...         │
└──────────────────────────────┘
```

## 6.2 Onboarding (3 pasos máximo)

Objetivo:
- Explicar con visuales, no con párrafos.

Pantalla 1: "Conoce a Arcobot"
- Arcobot saluda y anima al niño.

Pantalla 2: "Juega y aprende"
- Muestra 3 minijuegos representativos.

Pantalla 3: "Gana chispas"
- Explica recompensas y progreso.

Controles:
- Botón grande "Empezar".
- Opción "Saltar" pequeña para adulto.

## 6.3 Home

Objetivo:
- Entrar al juego en 1 toque.

Contenido:
1. Saludo visual con Arcobot.
2. CTA principal "Continuar aventura".
3. Accesos rápidos a 3 actividades recientes.
4. Progreso diario con barra energética.

Wireframe:
```text
┌──────────────────────────────┐
│ Arcobot + Hola [Niño]        │
│ [Barra de energía diaria]    │
│                              │
│ [ Botón gigante continuar ]  │
│                              │
│ [Act 1] [Act 2] [Act 3]      │
│                              │
│  Inicio  Mundos  Premios ... │
└──────────────────────────────┘
```

## 6.4 Selección de actividades o mundos

Objetivo:
- Elegir mundo por imagen y color.

Interacción:
1. Mapa desplazable horizontal por islas.
2. Cada isla tiene estado: disponible, en progreso, bloqueada.
3. Arcobot sugiere el siguiente reto.

## 6.5 Pantalla de juego

Objetivo:
- Concentración y acción clara.

Layout recomendado:
1. Arriba: progreso + botón pausar + ayuda.
2. Centro: zona interactiva grande.
3. Abajo: opciones/respuestas con botones grandes.
4. Arcobot en modo asistente contextual.

Patrones:
- Arrastrar y soltar.
- Tap para seleccionar.
- Repetir audio de instrucción.

## 6.6 Pantalla de éxito / error

Éxito:
1. Explosión de chispas + sonido breve.
2. Mensaje: "¡Lo lograste!"
3. Resumen claro de premio.
4. CTA: "Siguiente reto".

Error (sin castigo):
1. Arcobot empático: "Casi, intentemos juntos".
2. Pista visual inmediata.
3. Reintento instantáneo.

## 6.7 Sistema de recompensas

Objetivo:
- Visualizar progreso acumulado.

Contenido:
1. Álbum de stickers desbloqueados.
2. Medallas por hitos.
3. Barra de nivel de explorador.
4. Cofre semanal con animación.

## 6.8 Perfil del niño

Objetivo:
- Personalización simple y segura.

Contenido:
1. Avatar editable por partes.
2. Nombre corto o apodo.
3. Edad/rango escolar.
4. Historial visual de progreso.

## 6.9 Ajustes (modo adulto protegido)

Objetivo:
- Configuración sin interferir el juego.

Elementos:
1. Control de volumen música/voz.
2. Tiempo de juego diario.
3. Idioma.
4. Accesibilidad.
5. Gestión de perfiles.

Protección:
- "Puerta de adulto" con mini verificación (pregunta simple numérica).

---

## 7) Estrategia de gamificación

Sistema base:
1. Chispas: moneda blanda por actividad completada.
2. Estrellas: rendimiento en cada reto (1 a 3).
3. Niveles: cada 100 chispas sube rango.
4. Rachas: bonus por días consecutivos.

Reglas de diseño:
1. Siempre hay recompensa mínima por esfuerzo.
2. Las estrellas dependen de ayuda usada y precisión.
3. Evitar pérdida de progreso por fallar.

Eventos:
1. Cofre diario.
2. Misiones semanales temáticas.
3. Logros sorpresa de exploración.

---

## 8) Estrategias UX para atención y anti-frustración

1. Sesiones cortas: actividades de 2 a 5 minutos.
2. Objetivo visible constante: "Te faltan 2 pasos".
3. Instrucciones multimodales: texto corto + voz + demo visual.
4. Errores suaves: no usar rojo fuerte ni sonidos de fallo agresivos.
5. Dificultad adaptativa: si falla 2 veces, simplificar reto.
6. Reforzamiento positivo frecuente: microcelebraciones.
7. Carga cognitiva baja: máximo 3 acciones disponibles por pantalla.
8. Guardado automático al instante.

---

## 9) Accesibilidad para niños pequeños

1. Objetivo táctil mínimo: 56 dp.
2. Separación entre elementos táctiles: mínimo 12 dp.
3. Contraste texto/fondo: mínimo 4.5:1 para contenido clave.
4. No depender solo del color para estados; usar icono y forma.
5. Audio opcional en toda instrucción.
6. Modo "sin lectura": pictogramas y narración completa.
7. Animaciones con opción de reducción de movimiento.
8. Evitar timing estricto en tareas básicas.

---

## 10) Flujo completo de navegación

```text
Splash
  -> Onboarding (primera vez)
      -> Selección perfil niño
          -> Home
  -> Home (si ya existe sesión/perfil)

Home
  -> Continuar aventura
      -> Mundo actual
          -> Actividad
              -> Resultado (éxito/error)
                  -> Siguiente actividad o volver a mundo

Home -> Mundos
Home -> Premios
Home -> Perfil
Perfil -> Ajustes adulto
```

Flujos especiales:
1. Si la actividad se interrumpe, volver al último checkpoint.
2. Si no hay conexión, mostrar modo offline con actividades locales.

---

## 11) Recomendaciones técnicas de implementación en Flutter

## 11.1 Estructura UI sugerida

```text
lib/
  core/
    theme/
      app_theme.dart
      design_tokens.dart
    widgets/
      arcobot_avatar.dart
      arcobot_dialog_bubble.dart
      playful_button.dart
      reward_chip.dart
      progress_energy_bar.dart
      world_card.dart
  features/
    onboarding/
    home/
    worlds/
    game/
    rewards/
    profile/
    settings/
```

## 11.2 Widgets y librerías recomendadas

1. Estado: `flutter_riverpod` (ya está alineado con el proyecto).
2. Navegación: `go_router` (ya usado).
3. Animación personaje: `lottie` o `rive`.
4. SVG/ilustraciones: `flutter_svg`.
5. Audio guía: `just_audio`.
6. Efectos cortos: `audioplayers`.
7. Persistencia local: `shared_preferences` o `isar` según complejidad.

## 11.3 Sistema de diseño en código

Crear tokens tipados:
1. `ArcobotColors`
2. `ArcobotSpacing`
3. `ArcobotRadii`
4. `ArcobotTypography`
5. `ArcobotShadows`

Ventaja:
- Consistencia total entre pantallas.
- Cambios visuales globales rápidos.

## 11.4 Motion y feedback

1. Duraciones:
- Microinteracción: 120-180 ms.
- Transición de tarjeta: 220-280 ms.
- Celebración: 500-900 ms.

2. Curvas:
- Entrada: `Curves.easeOutBack`.
- Salida: `Curves.easeIn`.
- Flotación idle: animación suave infinita de 2-3 s.

## 11.5 Rendimiento

1. Precache de imágenes de mundos.
2. Reutilizar `const` widgets cuando sea posible.
3. Evitar rebuilds globales en juego, usar selectores por estado.
4. Cargar assets por demanda en módulos de mundos.

## 11.6 Arquitectura de contenido y assets

Estructura:
```text
assets/
  images/
    arcobot/
    worlds/
    rewards/
    ui/
  lottie/
    arcobot/
    feedback/
  audio/
    voice/
    sfx/
    music/
```

## 11.7 Instrumentación UX

Eventos analíticos clave:
1. `onboarding_completed`
2. `activity_started`
3. `activity_completed`
4. `hint_used`
5. `rage_tap_detected` (toques repetidos en zona no interactiva)
6. `session_duration`

Objetivo:
- Detectar fricción real y ajustar dificultad/flujo.

---

## 12) Comportamiento de Arcobot dentro de la app

Reglas globales:
1. Arcobot siempre está visible en momentos de decisión o duda.
2. No interrumpe cuando el niño está concentrado.
3. Si hay inactividad > 8 segundos, ofrece una pista.
4. En error, primero empatía; luego pista; luego ejemplo animado.
5. En éxito, celebra y conecta con el propósito: "¡Mini Arco ganó energía!".

Microcopys base:
1. "Toca aquí"
2. "Muy bien"
3. "Probemos otra vez"
4. "Te ayudo"
5. "Siguiente reto"

---

## 13) Roadmap de implementación sugerido (4 fases)

Fase 1:
1. Sistema de diseño (tokens + componentes base).
2. Home nueva + navegación base + Arcobot widget.

Fase 2:
1. Mundos + selección de actividades.
2. Pantalla de juego base + feedback éxito/error.

Fase 3:
1. Recompensas + perfil + ajustes adulto.
2. Audio guía e inactividad inteligente.

Fase 4:
1. Adaptación de dificultad.
2. Analítica UX y optimización de retención.

---

## 14) Criterios de calidad UX antes de release

1. Un niño puede iniciar una actividad en menos de 10 segundos.
2. Un niño puede completar una actividad sin ayuda adulta en el primer intento.
3. En caso de error, entiende qué hacer después en menos de 3 segundos.
4. Toda navegación crítica es posible con un solo pulgar.
5. No hay bloqueos de interacción durante animaciones no esenciales.

---

Este documento define la base de producto, diseño visual y plan técnico para implementar Mini Arco y Arcobot con una experiencia infantil premium y realista en Flutter.
