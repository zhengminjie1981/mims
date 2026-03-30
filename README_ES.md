# MIMS - Make Idea Make Sense

> **Haciendo las ideas razonables, claras y realizables**

---

## Resumen del Proyecto

MIMS es un agente de IA que toma la forma de "Guía MIMS", guiando a usuarios no técnicos a través del diseño de software mediante un diálogo proactivo de múltiples turnos, ayudando a transformar ideas vagas en modelos de dominio claros y prototipos interactivos.

MIMS se despliega para usuarios de Claude Code CLI, compuesto por tres componentes principales: la configuración de persona inyectada en el agente principal (`CLAUDE.md`), el flujo de trabajo estructurado (Skill), y los sub-agentes que manejan tareas atómicas.

### Concepto Central

**Make Idea Make Sense** - A través de un diálogo estructurado y asistencia de IA, ayudar a los usuarios a transformar ideas en prototipos:

- **Hacer las ideas claras** - Transformar requisitos vagos en conceptos organizados y comprensibles
- **Hacer las ideas visibles** - Visualizar y concretar conceptos abstractos
- **Hacer las ideas realizables** - Transformar ideas en prototipos interactivos

### Usuarios Objetivo

- **Gerentes de Producto** - Validar rápidamente ideas de productos
- **Analistas de Negocios** - Expresar claramente requisitos de negocio
- **Emprendedores** - Planificar MVPs (Productos Mínimos Viables)
- **Expertos del Dominio** - Diseñar software sin antecedentes técnicos

### Características Principales

1. **Sin Barrera Técnica** - Conversación en lenguaje cotidiano, sin herramientas que aprender
2. **Guía Proactiva de IA** - El agente hace preguntas proactivamente para clarificar requisitos
3. **Generación Automática de Modelos** - Construye automáticamente modelos de objetos de dominio a partir del diálogo
4. **Visualización Instantánea** - Muestra en tiempo real los cambios del modelo y las relaciones
5. **Prototipos Interactivos** - Genera prototipos que funcionan directamente en navegadores

---

## Significado del Nombre

**MIMS** = **M**ake **I**dea **M**ake **S**ense

**Pronunciación**: /mɪmz/

**Nombre Completo**: Make Idea Make Sense

- **Make** - Crear, construir, hacer... algo
- **Idea** - Idea, concepto, requisito, inspiración
- **Make Sense** - Volverse razonable, claro, organizado, comprensible

---

## Cómo Funciona

```
┌─────────────────────────────────────────────────────────────┐
│                    Bucle de Diálogo MIMS                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  El usuario presenta una idea/requisito                     │
│         ↓                                                   │
│  El agente de IA hace preguntas (clarificar, refinar)       │
│         ↓                                                   │
│  El usuario responde                                        │
│         ↓                                                   │
│  El agente actualiza automáticamente el modelo de dominio   │
│         ↓                                                   │
│  Mostrar el modelo para confirmación del usuario            │
│         ↓                                                   │
│  Retroalimentación/confirmación del usuario                 │
│         ↓                                                   │
│  El bucle continúa hasta que el modelo sea claro            │
│         ↓                                                   │
│  Generar prototipo interactivo                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Framework de Modelado**: MIMS adopta el framework **FBS (Function-Behavior-Structure)**, una ontología clásica en ciencias del diseño (Gero, 1990), que también corresponde altamente a los tres tipos de diagramas UML (Caso de Uso/Estado/Clase).

| Capa FBS | Preguntas Clave | Etapa de Diálogo |
|---------|----------------|------------------|
| **F Función** | ¿Quién lo usa? ¿Qué escenarios? ¿Qué tareas? | Análisis de roles y escenarios |
| **B Comportamiento** | ¿Qué estados? ¿Cómo operar? ¿Qué reglas? | Modelado de estados y operaciones |
| **S Estructura** | ¿Qué gestionar? ¿Qué información? ¿Cómo relacionada? | Modelado de objetos y relaciones de negocio |

> Orden de diálogo: descendente (F→B→S), salida del modelo: orden de dependencia (S→B→F)

---

## Inicio Rápido

### Instalación en Una Línea

**Método recomendado** (para todos los usuarios):

```bash
# Linux / macOS
cd /your-project
curl -sSL https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install.sh | bash
```

```powershell
# Windows PowerShell
cd C:\your-project
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install.ps1'))
```

**Proceso de instalación**:
1. Después de ejecutar el script, seleccione el método de instalación:
   - **Opción 1: Descarga automática (Recomendado)** - Descarga e instalación automáticas desde GitHub
   - **Opción 2: Descarga manual** - Descargar manualmente el zip desde GitLab/GitHub, luego proporcionar la ruta
2. El script instala los archivos en el **directorio actual**
3. Listo para usar después de la instalación

**Usuarios de Intranet Empresarial**: Si GitHub es inaccesible, use la **Opción 2** para descargar manualmente el archivo zip desde GitLab.

Guía de instalación detallada: [install/README.md](install/README.md)

### Comenzar

```bash
# 1. Navegar al directorio del proyecto
cd /your-project

# 2. Iniciar Claude Code
claude

# 3. Ingresar comando para comenzar
/mims design
```

---
- **Recomendado**: Usar los comandos de instalación en una línea arriba
- **Manual**: Copiar el contenido del directorio `impl/` a la raíz del proyecto del usuario
- Ver `impl/README.md` para detalles

---

## Dos Fases

### Fase 1: Modelado de Requisitos

Completado a través de diálogo (9 pasos):
1. **Recopilación de Requisitos** - Entender las ideas iniciales
2. **Comprensión del Contexto** - Entender el contexto del negocio y roles de usuario
3. **Análisis de Roles y Escenarios** - Definir escenarios de uso y participantes
4. **Mapeo de Procesos de Negocio** - Mapear los procesos de negocio principales
5. **Identificación de Objetos de Negocio** - Extraer las cosas a gestionar
6. **Modelado de Relaciones de Objetos** - Definir relaciones entre objetos y organización de módulos
7. **Modelado de Estados y Transiciones** - Definir estados de objetos y condiciones de transición
8. **Modelado de Operaciones y Reglas** - Definir operaciones y reglas de negocio
9. **Validación del Modelo** - Confirmar la completitud del modelo

**Salida**: `domain-model.yaml` (modelo de objetos de dominio)

### Fase 2: Generación de Prototipo

Generado a partir del modelo:
1. **Mapeo de Interfaz** - Diseñar la estructura de páginas
2. **Estilo de Interacción** - Determinar el formato de visualización (tabla/tarjeta/lista)
3. **Generación de Código** - Generar HTML/CSS/JS
4. **Vista Previa y Prueba** - Ver el prototipo en el navegador
5. **Iterar y Optimizar** - Ajustar según retroalimentación

**Salida**: `prototype/` (prototipo interactivo)

---

## Conceptos Clave (Lenguaje No Técnico)

| Capa FBS | Término Técnico | Nuestro Término | Ejemplo |
|---------|----------------|----------------|---------|
| F Función | Actor | Rol de Usuario | Administrador, Comprador, Cliente |
| F Función | Escenario | Escenario de Uso | Inventario diario, Verificación mensual |
| F Función | Proceso | Proceso de Negocio | Proceso completo de pedido a entrega |
| S Estructura | Objeto de Negocio | Cosas a gestionar | Cliente, Pedido, Producto |
| S Estructura | Atributo | Información/Campo | Nombre, Teléfono, Cantidad |
| S Estructura | Relación | Conexión/Vínculo | El cliente "tiene" múltiples pedidos |
| B Comportamiento | Estado | Estado Actual | Pendiente de pago, Enviado |
| B Comportamiento | Operación | Cosas que se pueden hacer | Aprobar, Enviar, Cancelar |
| B Comportamiento | Regla de Negocio | Restricción | Solo los administradores pueden aprobar |

---

## Principios de Diseño

1. **Usuario Primero** - Las necesidades y comprensión del usuario tienen prioridad sobre la perfección técnica
2. **Divulgación Progresiva** - Profundizar gradualmente, evitar sobrecarga de información
3. **Retroalimentación Instantánea** - Mostrar resultados inmediatamente después de cada paso
4. **Transparente y Controlable** - El usuario siempre controla la dirección del diálogo
5. **Rastreable** - Registrar todas las decisiones y cambios

---

## Estándares de Calidad

### Completitud
- ✅ Todos los campos obligatorios llenos
- ✅ Atributos de entidad ≥2
- ✅ Definiciones de relaciones claras
- ✅ Operaciones principales con reglas de negocio

### Consistencia
- ✅ Convenciones de nomenclatura unificadas
- ✅ Sin dependencias circulares
- ✅ Sin reglas de negocio conflictivas

### Confianza
- 90%-100%: Excelente - Recomendado proceder
- 70%-90%: Bueno - Preguntar si continuar
- 50%-70%: Regular - Recomendar mayor clarificación
- <50%: Bajo - Debe resolver problemas clave

---

## Gestión de Cambios

Soporta 4 niveles de cambio:

| Nivel | Tipo | Ejemplo | Manejo |
|-------|------|---------|--------|
| L1 | Ajuste Menor | Modificar nombre en chino | Cambio directo en el paso actual |
| L2 | Modificación Local | Modificar tipo de atributo | Volver al paso relacionado |
| L3 | Cambio Moderado | Agregar nueva entidad | Volver al inicio de la fase |
| L4 | Cambio Mayor | Eliminar entidad | Volver a la fase 1 o crear nuevo proyecto |

**Antes del Cambio**: Mostrar análisis de impacto
**Después del Cambio**: Validar consistencia

---

## Orígenes de la Filosofía de Diseño

Este proyecto se inspira en los siguientes métodos y conceptos:

- **Ontología FBS (Gero, 1990)** - Function-Behavior-Structure, fundación teórica del framework de modelado
- **UML (Lenguaje de Modelado Unificado)** - Diagramas de casos de uso (capa F), diagramas de clases (capa S), diagramas de estados (capa B)
- **Domain-Driven Design (DDD)** - Objetos de dominio, agregados, eventos de dominio
- **Harness Engineering (2026)** - Sistema de restricciones de agente impulsado por calidad
- **User Story Mapping** - Análisis de requisitos impulsado por escenarios
- **Diseño Conversacional** - Diseño de interacción en lenguaje natural

Ver: `docs/core/DESIGN.md`

---

## Restricciones Técnicas

| Restricción | Impacto | Mitigación |
|------------|---------|------------|
| Longitud del Contexto | Diálogos largos pueden exceder límites | Carga segmentada, persistencia de archivos |
| Concurrencia de Archivos | Múltiples sesiones pueden entrar en conflicto | Mecanismo de bloqueo de archivos |
| Complejidad del Prototipo | HTML/JS no puede implementar lógica backend | Clarificar límites del prototipo |
| Compatibilidad de Versión | Cambios de formato YAML | Gestión de números de versión |

---

## Licencia y Atribución

Este proyecto es documentación de diseño que describe la filosofía de diseño, arquitectura técnica y especificaciones de implementación de la herramienta MIMS (Make Idea Make Sense).

**Fecha de Creación**: 2026-03-21
**Versión Actual**: v1.1.0
**Estado de la Documentación**: Diseño e implementación completados

---

## Contacto y Retroalimentación

¿Preguntas o sugerencias? ¡Bienvenido a discutir!

---

**Hacer las ideas claras, hacer las ideas visibles, hacer las ideas realizables.**
