# CaveExplorer - Estado del proyecto

Actualizado: 12 de marzo de 2026

## Objetivo del juego
Crear un juego de exploración de cuevas con avance automático, decisiones por tiempo, múltiples finales y atmósfera de tensión para macOS (SwiftUI).

## Lo que ya está hecho
- Proyecto macOS migrado desde playground a app normal de Xcode con Tuist.
- Renombre completo a `CaveExplorer`.
- `bundleId` configurado como `com.charlesmoncada.caveExplorer`.
- Estructura modular por dominio usando SPM (`Packages/CaveModules`).
- Motor base de sesión/gameplay:
  - generación de ruta con decisiones y profundidad configurable,
  - estados de run (`traveling`, `waitingForChoice`, `ended`),
  - outcomes de derrota y final feliz.
- Flujo de UI:
  - pantalla de inicio,
  - inicio de partida,
  - overlay de juego,
  - retorno a home,
  - menú de settings como hoja/modal.
- Configuración de partida:
  - presets de dificultad,
  - parámetros ajustables (profundidad, tiempos).
- Render visual estilo cueva en primera persona:
  - túnel con movimiento,
  - iluminación/antorcha,
  - atmósfera (niebla, polvo, murciélagos),
  - efectos de urgencia cuando se acaba el tiempo.
- Timer de decisión visible en pantalla (barra decreciente).
- Audio:
  - SFX de eventos (`run started`, decisión, urgencia, selección, finales),
  - música de persecución de fondo,
  - controles de audio (mute + volumen de música + volumen de efectos),
  - mezcla dinámica por fase,
  - capa ambiental adicional (`ambient loop`) con mezcla dinámica.
- Calidad de código:
  - SwiftLint integrado como plugin SPM,
  - formato automatizado con script de `swift-format`,
  - tests unitarios ampliados para lógica de juego, settings, render builders y control de audio.

## Lo que falta (backlog)
- Jugabilidad:
  - balance de dificultad (timers, frecuencia de bifurcaciones, distribución de outcomes),
  - refinamiento de sensación de avance/velocidad por profundidad,
  - más variedad de eventos por nodo.
- Motor de mapa:
  - reglas más ricas para árbol de decisiones.
- Visual:
  - más capas/efectos para reforzar “caminata en cueva” (sombras, partículas contextuales, variación por bioma/zona),
  - pulido de feedback visual por peligro y por outcome final.
- Audio:
  - reemplazar/expandir efectos por librería de audio más cinematográfica,
  - ajustar niveles y transiciones para mezcla final,
  - añadir sonidos posicionales/contextuales (opcional).
- UX y producto:
  - comparar runs por semilla o dificultad (opcional, para telemetría local).
- Testing:
  - más tests de integración entre sesión + UI state,
  - smoke tests de audio controller ante cambios rápidos de estado.

## Avance reciente
- Generador de mapa actualizado para usar una ventana de profundidad explícita del final feliz (`happyEndingDepthRange`).
- El final feliz queda garantizado dentro del tramo configurado por `happyEndingStartPercent`.
- Se añadieron tests dedicados en dominio y motor de mapa para validar rango, borde al 100% y consistencia en múltiples seeds.
- Se implementó persistencia de preferencias con `UserDefaults` para settings de partida y audio.
- La app ahora carga preferencias guardadas al iniciar y persiste cambios automáticamente al ajustar settings o audio.
- Se añadieron tests unitarios del store de preferencias para defaults, normalización de valores fuera de rango y round-trip de guardado/carga.
- Se añadió pantalla de resumen al finalizar cada run con outcome, mensaje descriptivo y progreso de profundidad alcanzada.
- Se incorporó `CaveRunSummary` como capa de lógica de resumen para separar cómputo de métricas y presentación en UI.
- Se agregaron tests de lógica del resumen para éxito/fracaso y límites de progreso.
- Se agregó persistencia de mejores runs (profundidad máxima y escapes acumulados) con guardado en `UserDefaults`.
- Home ahora muestra un resumen histórico de progreso para retomar contexto entre sesiones.
- Se extendieron tests de preferencias y de lógica de estadísticas para cubrir normalización y actualización de métricas.
- Se añadió onboarding breve en home con micro-guía de flujo y controles básicos.
- El onboarding puede ocultarse con "Entendido" y su estado queda persistido para no volver a mostrarlo en próximos inicios.
- Se cubrió la persistencia del flag de onboarding con tests del store de preferencias.
- Se amplió el resumen de fin de run con tiempo estimado, seed usada y cantidad de decisiones tomadas.
- Se agregó persistencia de historial corto de runs recientes y visualización del historial en home.
- Se añadieron tests para líneas extendidas del resumen y para persistencia/recorte del historial reciente.
- Se separó `ContentView` en vistas por responsabilidad (`CaveGameplayOverlayViews` y `CaveHomeOverlayViews`) para reducir tamaño de archivo y mejorar mantenibilidad.
- Se regeneró el proyecto con Tuist para incluir nuevos archivos de vistas sin romper el target.
- Desaparecieron los warnings de SwiftLint por longitud de archivo/función en la ruta principal de UI.

## Aprendizajes hasta ahora
- Separar dominio (SPM) de la app (SwiftUI) facilitó probar la lógica sin depender de UI ni audio real.
- Commits pequeños por bloque aceleraron iteración y redujeron regresiones al detectar fallos temprano.
- Probar cada bloque con `format` + `tests` antes de comitear evitó arrastrar deuda entre iteraciones.
- El audio mejora mucho con capas (música + ambiente + SFX) y mezcla dinámica por estado, más que con un solo track constante.
- En macOS, cambios de actor isolation pueden romper compilación en inicializadores con defaults; conviene validar eso en cada refactor de MainActor.
- Tener settings desde home (y no siempre visibles en gameplay) mejora claridad y evita sobrecargar pantalla de juego.
- El timer visual de decisión da feedback inmediato y es clave para la tensión del loop principal.
- Mantener backlog vivo en este archivo ayuda a retomar rápido sin perder contexto de producto.

## Cómo retomar rápido otro día
1. `tuist generate`
2. Abrir `CaveExplorer.xcodeproj`
3. Correr esquema `CaveExplorer` en destino `My Mac`
4. Para validar calidad antes de commit:
   - `./scripts/format.sh`
   - `./scripts/format-check.sh`
   - `xcodebuild test -project CaveExplorer.xcodeproj -scheme CaveExplorer -destination 'platform=macOS'`

## Próximo bloque sugerido
- Añadir tests unitarios para el flujo de persistencia de historial reciente al finalizar run (integración `CaveSession` + `CavePreferencesStore`) y limitar explícitamente el tamaño visible del historial en home con constantes compartidas.
