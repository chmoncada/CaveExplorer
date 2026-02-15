# CaveExplorer - Estado del proyecto

Actualizado: 15 de febrero de 2026

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
  - reglas más ricas para árbol de decisiones,
  - controlar explícitamente que el final feliz aparezca en el último 20% (y hacerlo configurable en settings).
- Visual:
  - más capas/efectos para reforzar “caminata en cueva” (sombras, partículas contextuales, variación por bioma/zona),
  - pulido de feedback visual por peligro y por outcome final.
- Audio:
  - reemplazar/expandir efectos por librería de audio más cinematográfica,
  - ajustar niveles y transiciones para mezcla final,
  - añadir sonidos posicionales/contextuales (opcional).
- UX y producto:
  - onboarding breve para explicar controles,
  - pantalla de resumen al terminar (causa de muerte / estadísticas de run),
  - persistencia básica de preferencias y mejores runs.
- Testing:
  - más tests de integración entre sesión + UI state,
  - tests para reglas avanzadas del generador de mapa,
  - smoke tests de audio controller ante cambios rápidos de estado.

## Cómo retomar rápido otro día
1. `tuist generate`
2. Abrir `CaveExplorer.xcodeproj`
3. Correr esquema `CaveExplorer` en destino `My Mac`
4. Para validar calidad antes de commit:
   - `./scripts/format.sh`
   - `./scripts/format-check.sh`
   - `xcodebuild test -project CaveExplorer.xcodeproj -scheme CaveExplorer -destination 'platform=macOS'`

## Próximo bloque sugerido
- Implementar reglas avanzadas del generador para controlar la ubicación del final feliz (último 20%), con tests dedicados y settings preparado para exponerlo en UI.
