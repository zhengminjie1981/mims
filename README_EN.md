# MIMS - Make Idea Make Sense

> A conversational AI guide for turning vague software ideas into clear requirements, design documents, and clickable HTML prototypes.

**Version**: 1.5.1

## What Is MIMS?

MIMS installs into AI coding tools such as Claude Code, Codex, and Cursor. It guides non-technical users through software design in plain language and generates:

- `domain-model.yaml`: structured domain model
- `srs.md`: software requirements specification
- `sdd.md`: software design document
- `prototype/`: zero-dependency HTML prototype

MIMS v1.5.1 brings upgrade-chain hardening and project lifecycle management:

- Upgrade chain: intranet GitLab private repos use the `/api/v4` + token auth; bootstrap hardened with `-fsSL` + script-header check; packages ship a `SHA256SUMS` integrity check; pre-upgrade snapshots with one-click rollback; local edits preserved as `.local`.
- Project lifecycle: `/mims status|pause|resume|persist|detach` — pause MIMS to enter development, resume when needed.
- Work-product relocation: optionally move design artifacts to `design/` on pause; auto-located on resume.
- Versioning: `mims update --check` / `--edge`; `.mims-commit` tracks the content source.

## Install or Update

Install once and use MIMS in all projects.

If MIMS is already installed, prefer the local updater. By default, it reads the previous install source from `~/.mims/install-state.json` and updates from that source (GitHub or GitLab):

```powershell
& "$HOME\.mims\update.ps1"
```

Linux / macOS:

```bash
bash ~/.mims/update.sh
```

For GitLab/internal network updates:

```powershell
& "$HOME\.mims\update.ps1" -Source gitlab
```

```bash
bash ~/.mims/update.sh gitlab
```

You can also rerun the install command below. The update overwrites the global MIMS Skill and Agents, but does not overwrite project files such as `domain-model.yaml`, `srs.md`, `sdd.md`, `prototype/`, `CLAUDE.md`, or `AGENTS.md`.

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

For internal network or VPN users.

Linux / macOS:

```bash
curl -sSL https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/raw/main/install/install-global.sh | bash
```

Windows PowerShell:

```powershell
iex ((New-Object System.Net.WebClient).DownloadString('https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/raw/main/install/install-global.ps1'))
```

## Start

Open your project folder and start your AI coding tool:

```bash
cd /your-project
```

Claude Code:

```text
/mims design
```

Codex or tools where slash commands are not reliable:

```text
Use MIMS to help me start requirements modeling.
```

## Commands

| Command | Purpose |
|---|---|
| `/mims` | Show help |
| `/mims design` | Start or continue design |
| `/mims model` | Show current design summary |
| `/mims status` | Show MIMS activation status for this project |
| `/mims validate` | Validate the model |
| `/mims prototype` | Generate HTML prototype |
| `/mims change` | Change existing design |
| `/mims srs` | Generate requirements document |
| `/mims sdd` | Generate design document |
| `/mims pause` | Pause project-level MIMS activation for development |
| `/mims resume` | Temporarily enable MIMS for this session |
| `/mims persist` | Persistently re-enable MIMS in this project |
| `/mims detach` | Remove the project-level MIMS entry |

After design is complete and the project enters development, use `/mims pause` to stop project-level MIMS activation. This does not uninstall MIMS or delete `domain-model.yaml`, `srs.md`, `sdd.md`, or `prototype/`. Use `/mims resume` for a temporary session or `/mims persist` to re-enable persistent activation.

## Generated Files

| File | Purpose |
|---|---|
| `domain-model.yaml` | Persistent domain model and progress |
| `srs.md` | Requirements document |
| `sdd.md` | Design document |
| `prototype/` | Clickable browser prototype |

## Notes

MIMS is best for business systems, workflows, internal tools, CRM/ERP-like systems, and early product validation. Generated prototypes are for review and communication, not production deployment.

## License

MIT License
