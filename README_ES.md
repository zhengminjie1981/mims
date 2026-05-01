# MIMS - Make Idea Make Sense

> **Hacer las ideas razonables, claras y realizables**

---

## Resumen del Proyecto

MIMS es un Agente de IA que toma la forma de "迷悟师" (Guía MIMS), guiando a usuarios no técnicos a través del diseño de software mediante diálogo proactivo multi-turno, ayudando a transformar ideas vagas en modelos de dominio claros y prototipos interactivos.

MIMS está desplegado para usuarios de Claude Code CLI, y consta de tres componentes principales: configuración de persona inyectada en el Agente principal (`CLAUDE.md`), flujo de trabajo estructurado (Skill) y sub-agentes que manejan tareas atómicas.

### Concepto Central

**Make Idea Make Sense** - A través de diálogo estructurado y asistencia de IA, ayudar a los usuarios a transformar ideas en prototipos:

- **Hacer las ideas claras** - Transformar requisitos vagos en conceptos organizados y comprensibles
- **Hacer las ideas visibles** - Visualizar y concretar conceptos abstractos
- **Hacer las ideas realizables** - Transformar ideas en prototipos interactivos

### Usuarios Objetivo

- **Gerentes de Producto** - Validar rápidamente ideas de producto
- **Analistas de Negocio** - Expresar claramente los requisitos de negocio
- **Emprendedores** - Planificar MVPs (Productos Mínimos Viables)
- **Expertos de Dominio** - Diseñar software sin conocimientos técnicos

### Características Clave

1. **Barrera Técnica Cero** - Conversación en lenguaje cotidiano, sin herramientas que aprender
2. **Orientación por IA** - El Agente pregunta proactivamente para aclarar requisitos
3. **Generación Automática de Modelos** - Construye automáticamente modelos de objetos de dominio a partir del diálogo
4. **Visualización Instantánea** - Muestra en tiempo real los cambios y relaciones del modelo
5. **Prototipos Interactivos** - Genera prototipos que se ejecutan directamente en navegadores

---

## Significado del Nombre

**MIMS** = **M**ake **I**dea **M**ake **S**ense

**Pronunciación**: /mɪmz/

**Nombre Completo**: Make Idea Make Sense

- **Make** - Crear, construir, hacer... que algo se convierta en
- **Idea** - Pensamiento, concepto, requisito, inspiración
- **Make Sense** - Volverse razonable, claro, organizado, comprensible

---

## Cómo Funciona

```
┌─────────────────────────────────────────────────────────────┐
│                   Bucle de Diálogo MIMS                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  El usuario presenta una idea/requisito                     │
│         ↓                                                   │
│  El Agente de IA hace preguntas (aclarar, refinar, completar)│
│         ↓                                                   │
│  El usuario responde                                        │
│         ↓                                                   │
│  El Agente actualiza automáticamente el modelo de dominio   │
│         ↓                                                   │
│  Muestra el modelo para confirmación del usuario            │
│         ↓                                                   │
│  Comentarios/confirmación del usuario                       │
│         ↓                                                   │
│  El bucle continúa hasta que el modelo sea claro y completo │
│         ↓                                                   │
│  Genera un prototipo interactivo                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Framework de Modelado**: MIMS adopta el framework **FBS (Function-Behavior-Structure)**, una ontología clásica en la ciencia del diseño (Gero, 1990), que también se corresponde altamente con los tres tipos principales de diagramas UML (Diagramas de Caso de Uso/Estado/Clase).

| Capa FBS | Preguntas Clave | Etapa de Diálogo |
|----------|-----------------|------------------|
| **F Función** | ¿Quién lo usa? ¿Qué escenarios? ¿Qué tareas? | Análisis de Roles y Escenarios |
| **B Comportamiento** | ¿Qué estados? ¿Cómo operar? ¿Qué reglas? | Modelado de Estados y Operaciones |
| **S Estructura** | ¿Qué gestionar? ¿Qué información? ¿Cómo se relaciona? | Modelado de Objetos de Negocio y Relaciones |

> Orden del diálogo: de arriba hacia abajo (F→B→S), salida del modelo: orden de dependencia (S→B→F).

---

## Arquitectura Técnica

```
Capa de Diálogo      Capa de Datos      Capa de Generación      Capa de Documentación
CLAUDE.md            Modelo YAML        Prototipo HTML/JS       Documentos Markdown
+ Skill
+ Sub-agentes
```

### Stack Tecnológico

| Capa | Tecnología | Justificación |
|------|-----------|---------------|
| Persona y Comportamiento Base | CLAUDE.md | Inyección T0 en el Agente principal, siempre activo |
| Flujo de Trabajo de Diálogo | AI CLI Skill | Carga bajo demanda, disparadores estandarizados |
| Tareas de Prototipo/Validación | AI CLI Sub-agents | Aislamiento de tareas atómicas, sin contaminación de contexto |
| Almacenamiento de Datos | YAML | Legible por humanos, compatible con IA |
| Generación de Prototipos | HTML/CSS/JS | Sin dependencias, se ejecuta directamente en navegadores |
| Salida de Documentación | Markdown | Fácil de leer, fácil de controlar versiones |

---

## Estructura de Documentos

```
MIMS/
├── README.md                           # Este documento
├── CLAUDE.md                           # Guía de implementación del proyecto (cargado automáticamente por Claude Code)
├── impl/                               # Archivos de implementación desplegables
│   ├── README.md                       # Instrucciones de instalación (incluye guía para agentes AI)
│   ├── CLAUDE.md                       # Persona MIMS (Claude Code, inyección T0)
│   └── .claude/
│       ├── agents/
│       │   ├── mims-validator.md       # Sub-agente de validación de modelos (4 modos)
│       │   ├── mims-prototyper.md      # Sub-agente de generación de prototipos
│       │   ├── mims-change-manager.md  # Sub-agente de gestión de cambios
│       │   └── mims-spec-generator.md  # Sub-agente de generación de documentos SRS/SDD
│       └── skills/mims/
│           ├── SKILL.md                # Flujo de trabajo de modelado de requisitos y generación de prototipos
│           └── references/             # Base de conocimiento (bajo demanda)
│               ├── schema.md           # Schema Core §1-5
│               ├── schema-examples.md  # Conjuntos de datos de ejemplo (bajo demanda)
│               ├── persona-rules.md    # Reglas de persona y diálogo
│               ├── claude-md-template.md # Plantilla CLAUDE.md para proyecto de usuario
│               ├── prompt-ref.md       # Plantillas de prompts (referencia para desarrolladores)
│               ├── iteration-rules.md  # Reglas de iteración de diseño
│               ├── workflow-common.md  # Mecanismos comunes entre fases
│               ├── workflow-preliminary.md  # Diseño preliminar P1-P6
│               ├── workflow-detailed.md     # Diseño detallado D1-D5
│               ├── workflow-prototype.md    # Generación de prototipo R1-R9
│               ├── srs-template.md     # Plantilla de documento SRS
│               └── sdd-template.md     # Plantilla de documento SDD
│
└── docs/                               # Todos los documentos de diseño
    ├── core/                           # Especificaciones de diseño principales
    │   ├── DESIGN.md                   # Decisiones y principios de diseño
    │   └── PERSONA.md                  # Persona del Agente de IA
    │
    ├── progress/                       # Progreso y análisis
    │   └── PROJECT_PROGRESS.md         # Informe de progreso del proyecto
    │
    └── archive/                        # Documentos archivados (referencia histórica)
```

## Guía de Lectura

| Si deseas... | Lectura recomendada |
|-------------|---------------------|
| Entender qué es el proyecto | `README.md` (este documento) |
| Entender las decisiones de diseño | `docs/core/DESIGN.md` |
| Entender las especificaciones de comportamiento del Agente | `docs/core/PERSONA.md` |
| Ver el flujo de trabajo completo | `impl/.claude/skills/mims/SKILL.md` + `references/` |
| Entender el manejo de cambios | `references/iteration-rules.md` |
| Ver las definiciones del Schema | `references/schema.md` + `references/schema-examples.md` |

---

## Tres Fases

### Fase 1: Diseño Preliminar

Completado a través del diálogo (6 pasos):
1. **P1 Recopilación y Preparación de Requisitos** - Comprender las ideas iniciales, guiar la preparación de materiales
2. **P2 Comprensión de Materiales** (opcional) - Analizar los materiales proporcionados por el usuario
3. **P3 Contexto y Objetivos** - Comprender el contexto de negocio y los objetivos generales
4. **P4 Roles y Escenarios** - Definir roles de usuario y casos de uso (muchos-a-muchos)
5. **P5 Procesos de Negocio** - Mapear los procesos principales (montados en escenarios, flujo de información)
6. **P6 Visión General de Arquitectura** - División en módulos, interfaces externas, evaluación de Agent AI

**Punto de control**: Validación preliminar → generar `srs.md`

**Salida**: `domain-model.yaml` (capa F + módulos) + `srs.md` (Especificación de Requisitos de Software)

### Fase 2: Diseño Detallado

Modelado en profundidad (5 pasos):
1. **D1 Reconocimiento de Objetos de Negocio** - Extraer las cosas a gestionar y sus atributos
2. **D2 Relaciones y Asignación a Módulos** - Definir relaciones, asignación a módulos, diseño de Agent AI
3. **D3 Estados y Ciclo de Vida** - Definir estados de objetos y condiciones de transición
4. **D4 Operaciones y Reglas de Negocio** - Definir operaciones y reglas de negocio
5. **D5 Validación del Modelo y Confianza** - Validar la completitud del modelo, evaluar la confianza

**Punto de control**: Validación completa → generar `sdd.md`

**Salida**: `domain-model.yaml` (FBS completo) + `sdd.md` (Documento de Diseño de Software)

### Fase 3: Generación de Prototipo

Generado a partir del modelo (9 pasos):
1. **R1 Análisis del Modelo** - Analizar las características de los datos del modelo
2. **R2 Permisos de Páginas** - Asignar permisos de página por rol
3. **R3 Mapeo de Funciones** - Mapear operaciones a funciones de página
4. **R4 Diseño de Flujos** - Diseñar navegación y flujos de páginas
5. **R5 Estructura de Páginas** - Recomendar el diseño según las características de los datos
6. **R6 Interacción de Páginas** - Determinar los patrones de interacción
7. **R7 Generación de Código** - Generar HTML/CSS/JS (delegado al prototipador)
8. **R8 Validación de Procesos** - Validación de extremo a extremo con los procesos de negocio
9. **R9 Entrega** - Entregar el prototipo, guiar la experiencia

**Salida**: `prototype/` (prototipo interactivo con workbench orientado a procesos y consejos de experiencia en página)

### Gestión de Procesos

- **Reanudar**: Continuar desde el último punto de control tras una interrupción
- **Iteración de Diseño**: Soportar cambios durante el diseño y después de la entrega del prototipo, con evaluación automática de impacto
- **Niveles de Cambio**: L1 ajuste menor → L4 cambio mayor, cada uno con diferente alcance de retroceso

---

## Conceptos Clave (Lenguaje No Técnico)

| Capa FBS | Término Técnico | Nuestro Término | Ejemplo |
|----------|-----------------|-----------------|---------|
| F Función | Actor | Rol de Usuario | Administrador, Comprador, Cliente |
| F Función | Escenario | Caso de Uso | Registro diario, Inventario mensual |
| F Función | Proceso | Proceso de Negocio | Proceso completo de pedido a entrega |
| S Estructura | Objeto de Negocio | Cosas a gestionar | Cliente, Pedido, Producto |
| S Estructura | Atributo | Información/Campo | Nombre, Teléfono, Cantidad |
| S Estructura | Relación | Asociación/Vínculo | Cliente "tiene" múltiples Pedidos |
| B Comportamiento | Estado | Estado Actual | Pendiente de pago, Enviado |
| B Comportamiento | Operación | Acción Disponible | Aprobar, Enviar, Cancelar |
| B Comportamiento | Regla de Negocio | Restricción | Solo los administradores pueden aprobar |

---

## Principios de Diseño

1. **Usuario Primero** - Las necesidades y la comprensión del usuario tienen prioridad sobre la perfección técnica
2. **Divulgación Progresiva** - Profundidad gradual, evitar sobrecarga de información
3. **Retroalimentación Instantánea** - Mostrar resultados inmediatamente después de cada paso
4. **Transparente y Controlable** - El usuario siempre controla la dirección del diálogo
5. **Trazable** - Registrar todas las decisiones y cambios

---

## Estándares de Calidad

### Completitud
- ✅ Todos los campos requeridos están completos
- ✅ Atributos de entidad >= 2
- ✅ Relaciones claramente definidas
- ✅ Las operaciones principales tienen reglas de negocio

### Consistencia
- ✅ Convenciones de nomenclatura unificadas
- ✅ Sin dependencias circulares
- ✅ Sin reglas de negocio en conflicto

### Confianza
- 90%-100%: Excelente - Proceder al siguiente paso
- 70%-90%: Bueno - Preguntar si se debe proceder
- 50%-70%: Regular - Recomendar mayor aclaración
- <50%: Bajo - Deben resolverse los problemas clave

---

## Gestión de Cambios

Los cambios son soportados tanto durante el diseño como después de la entrega del prototipo. Ver `references/iteration-rules.md` para más detalles.

Soporta 4 niveles de cambio:

| Nivel | Tipo | Ejemplo | Manejo |
|-------|------|---------|--------|
| L1 | Ajuste Menor | Cambiar nombre mostrado | Modificar directamente en el paso actual |
| L2 | Modificación Parcial | Cambiar tipo de atributo | Volver al paso relacionado |
| L3 | Cambio Moderado | Agregar nueva entidad | Volver al inicio de la fase |
| L4 | Cambio Mayor | Eliminar entidad | Volver al diseño preliminar o crear nuevo proyecto |

**Antes del cambio**: Mostrar análisis de impacto
**Después del cambio**: Validar consistencia, sincronizar modelo y prototipo

---

## Inicio Rápido

### Instalación y Uso

Para instrucciones completas de instalación, actualización, verificación y uso, consulta **[`impl/README.md`](impl/README.md)**.

Experiencia rápida:

```bash
cd /your-project
curl -sSL https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install.sh | bash  # Linux/macOS
# Windows PowerShell:
# iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install.ps1'))
```

### Como Usuario

1. **Preparar** - Tener una idea o requisito inicial
2. **Iniciar** - Ejecutar el comando `/mims design`
3. **Diseño Preliminar** - Responder las preguntas del Guía (P1-P6)
4. **Diseño Detallado** - Profundizar en objetos, estados y reglas (D1-D5)
5. **Generar Prototipo** - Generar prototipo a partir del modelo (R1-R9)
6. **Iterar** - Ajustar el diseño según los comentarios (`/mims change`)
7. **Validar** - Ver el prototipo en el navegador

### Como Desarrollador

**Leer Documentación**:
- Entender la arquitectura del proyecto y el despliegue desde `CLAUDE.md`
- Entender las decisiones de diseño desde `docs/core/DESIGN.md`
- Entender el persona y comportamiento del Agente desde `docs/core/PERSONA.md`
- Entender el flujo de trabajo completo desde `impl/.claude/skills/mims/SKILL.md` + `references/`

**Despliegue**:
- **Recomendado**: Usar el script de instalación (ver `impl/README.md`), que gestiona automáticamente los archivos de compatibilidad con Codex
- **Manual**: Copiar el contenido del directorio `impl/` a la raíz del proyecto; requiere la creación adicional de `AGENTS.md` y `.agents/` (ver método 2 en `impl/README.md`)
- **Agente de IA**: Los agentes de IA NO deben copiar directamente `impl/`; en su lugar, descargar y ejecutar el script de instalación (ver método 3 en `impl/README.md`)

---

## Filosofía de Diseño

MIMS se inspira en las siguientes metodologías y conceptos:

- **Ontología FBS (Gero, 1990)** - Function-Behavior-Structure, base teórica del framework de modelado
- **UML (Lenguaje de Modelado Unificado)** - Diagramas de caso de uso (capa F), diagramas de clase (capa S), diagramas de estado (capa B)
- **DDD (Diseño Guiado por el Dominio)** - Objetos de dominio, agregados, eventos de dominio
- **Harness Engineering (2026)** - Sistema de restricción de Agentes basado en calidad
- **User Story Mapping** - Análisis de requisitos orientado a escenarios
- **Conversational Design** - Diseño de interacción en lenguaje natural

Ver: `docs/core/DESIGN.md`

---

## Restricciones Técnicas

| Restricción | Impacto | Mitigación |
|-------------|---------|------------|
| Longitud de Contexto | Diálogos largos pueden exceder límites | Carga segmentada, persistencia en archivos |
| Concurrencia de Archivos | Conflictos multi-sesión | Mecanismo de bloqueo de archivos |
| Complejidad del Prototipo | HTML/JS no puede implementar lógica de backend | Definir límites claros del prototipo |
| Compatibilidad de Versiones | Cambios en formato YAML | Gestión de números de versión |

---

## Licencia y Atribución

Este proyecto es un repositorio de documentos de diseño que describe la filosofía de diseño, la arquitectura técnica y las especificaciones de implementación de la herramienta MIMS (Make Idea Make Sense).

**Creado**: 2026-03-21
**Versión Actual**: v1.4
**Estado**: Diseño e implementación completados

---

## Contacto y Comentarios

¡Preguntas y sugerencias son bienvenidas!

---

**Hacer las ideas claras, hacer las ideas visibles, hacer las ideas realizables.**
