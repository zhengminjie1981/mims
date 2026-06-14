# MIMS - Make Idea Make Sense

> Una guia conversacional de IA para convertir ideas de software vagas en requisitos claros, documentos de diseno y prototipos HTML interactivos.

**Version**: 1.4

## Que es MIMS?

MIMS se instala en herramientas como Claude Code, Codex y Cursor. Guia a usuarios no tecnicos mediante lenguaje natural y genera:

- `domain-model.yaml`: modelo de dominio estructurado
- `srs.md`: especificacion de requisitos de software
- `sdd.md`: documento de diseno de software
- `prototype/`: prototipo HTML sin dependencias

MIMS v1.4 refuerza la compatibilidad con Codex y el control de calidad del modelo:

- En Codex, los disparadores en lenguaje natural funcionan mediante `AGENTS.md`.
- Si los subagentes no estan disponibles, MIMS usa un fallback basado en reglas equivalentes.
- Una fase solo puede marcarse como completada despues de registrar `metadata.validation`.
- Los documentos SRS/SDD conservan ids del modelo para rastrear hasta `domain-model.yaml`.
- Los prototipos se generan por defecto en la ruta relativa `prototype/`, no en rutas absolutas dependientes de la maquina.

## Instalacion o actualizacion

Instala una vez y usa MIMS en todos tus proyectos.

Si MIMS ya esta instalado, se recomienda usar primero el updater local. De forma predeterminada, lee la fuente de instalacion anterior desde `~/.mims/install-state.json` y actualiza desde esa fuente (GitHub o GitLab):

```powershell
& "$HOME\.mims\update.ps1"
```

Linux / macOS:

```bash
bash ~/.mims/update.sh
```

Para actualizar desde GitLab / red interna:

```powershell
& "$HOME\.mims\update.ps1" -Source gitlab
```

```bash
bash ~/.mims/update.sh gitlab
```

Tambien puedes volver a ejecutar el comando de instalacion siguiente. La actualizacion sobrescribe el Skill y los Agents globales de MIMS, pero no sobrescribe archivos del proyecto como `domain-model.yaml`, `srs.md`, `sdd.md`, `prototype/`, `CLAUDE.md` o `AGENTS.md`.

### GitHub

Linux / macOS:

```bash
curl -sSL https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.sh | bash
```

Windows PowerShell:

```powershell
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.ps1'))
```

### GitLab

Para usuarios de red interna o VPN.

Linux / macOS:

```bash
curl -sSL https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/raw/main/install/install-global.sh | bash
```

Windows PowerShell:

```powershell
iex ((New-Object System.Net.WebClient).DownloadString('https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/raw/main/install/install-global.ps1'))
```

## Empezar

Abre la carpeta de tu proyecto:

```bash
cd /your-project
```

Claude Code:

```text
/mims design
```

Codex u otras herramientas donde los slash commands no sean fiables:

```text
Usa MIMS para empezar a modelar requisitos.
```

## Comandos

| Comando | Uso |
|---|---|
| `/mims` | Mostrar ayuda |
| `/mims design` | Iniciar o continuar el diseno |
| `/mims model` | Ver resumen del diseno actual |
| `/mims status` | Ver el estado de activacion de MIMS en este proyecto |
| `/mims validate` | Validar el modelo |
| `/mims prototype` | Generar prototipo HTML |
| `/mims change` | Cambiar un diseno existente |
| `/mims srs` | Generar documento de requisitos |
| `/mims sdd` | Generar documento de diseno |
| `/mims pause` | Pausar la activacion de MIMS en el proyecto para pasar a desarrollo |
| `/mims resume` | Activar MIMS temporalmente en esta sesion |
| `/mims persist` | Reactivar MIMS de forma persistente en el proyecto |
| `/mims detach` | Eliminar la entrada MIMS a nivel de proyecto |

Cuando el diseno termine y el proyecto pase a desarrollo, usa `/mims pause` para pausar la activacion de MIMS en este proyecto. Esto no desinstala MIMS ni elimina `domain-model.yaml`, `srs.md`, `sdd.md` o `prototype/`. Usa `/mims resume` para una sesion temporal o `/mims persist` para reactivar la activacion persistente.

## Archivos generados

| Archivo | Descripcion |
|---|---|
| `domain-model.yaml` | Modelo de dominio y progreso |
| `srs.md` | Documento de requisitos |
| `sdd.md` | Documento de diseno |
| `prototype/` | Prototipo para abrir en el navegador |

## Casos adecuados

MIMS es adecuado para sistemas de gestion, flujos de trabajo, herramientas internas, sistemas tipo CRM/ERP y validacion temprana de producto. Los prototipos generados son para revision y comunicacion, no para produccion.

## Licencia

MIT License
