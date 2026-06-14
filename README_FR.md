# MIMS - Make Idea Make Sense

> Un guide IA conversationnel pour transformer une idee logicielle vague en exigences claires, documents de conception et prototype HTML cliquable.

**Version** : 1.4

## Qu'est-ce que MIMS ?

MIMS s'installe dans des outils comme Claude Code, Codex et Cursor. Il guide les utilisateurs non techniques avec un dialogue en langage naturel et genere :

- `domain-model.yaml` : modele de domaine structure
- `srs.md` : specification des exigences logicielles
- `sdd.md` : document de conception logicielle
- `prototype/` : prototype HTML sans dependance

MIMS v1.4 renforce la compatibilite Codex et le controle qualite du modele :

- Dans Codex, les declencheurs en langage naturel fonctionnent via `AGENTS.md`.
- Si les sous-agents ne sont pas disponibles, MIMS utilise un fallback base sur les memes regles.
- Une phase ne peut etre marquee terminee qu'apres l'enregistrement de `metadata.validation`.
- Les documents SRS/SDD conservent les ids du modele pour remonter a `domain-model.yaml`.
- Les prototypes sont generes par defaut dans le chemin relatif `prototype/`, pas dans des chemins absolus propres a une machine.

## Installation ou mise a jour

Installez une fois, puis utilisez MIMS dans tous vos projets.

Si MIMS est deja installe, utilisez de preference l'updater local. Par defaut, il lit la source d'installation precedente dans `~/.mims/install-state.json` et met a jour depuis cette source (GitHub ou GitLab) :

```powershell
& "$HOME\.mims\update.ps1"
```

Linux / macOS :

```bash
bash ~/.mims/update.sh
```

Pour une mise a jour via GitLab / reseau interne :

```powershell
& "$HOME\.mims\update.ps1" -Source gitlab
```

```bash
bash ~/.mims/update.sh gitlab
```

Vous pouvez aussi relancer la commande d'installation ci-dessous. La mise a jour remplace le Skill et les Agents MIMS globaux, mais ne remplace pas les fichiers du projet comme `domain-model.yaml`, `srs.md`, `sdd.md`, `prototype/`, `CLAUDE.md` ou `AGENTS.md`.

### GitHub

Linux / macOS :

```bash
curl -sSL https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.sh | bash
```

Windows PowerShell :

```powershell
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.ps1'))
```

### GitLab

Pour les utilisateurs du reseau interne ou du VPN.

Linux / macOS :

```bash
curl -sSL https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/raw/main/install/install-global.sh | bash
```

Windows PowerShell :

```powershell
iex ((New-Object System.Net.WebClient).DownloadString('https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/raw/main/install/install-global.ps1'))
```

## Demarrer

Ouvrez le dossier de votre projet :

```bash
cd /your-project
```

Claude Code :

```text
/mims design
```

Codex ou autres outils ou les slash commands ne sont pas fiables :

```text
Utilise MIMS pour commencer la modelisation des besoins.
```

## Commandes

| Commande | Usage |
|---|---|
| `/mims` | Afficher l'aide |
| `/mims design` | Demarrer ou reprendre la conception |
| `/mims model` | Afficher le resume actuel |
| `/mims status` | Afficher l'etat d'activation MIMS du projet |
| `/mims validate` | Valider le modele |
| `/mims prototype` | Generer un prototype HTML |
| `/mims change` | Modifier une conception existante |
| `/mims srs` | Generer le document d'exigences |
| `/mims sdd` | Generer le document de conception |
| `/mims pause` | Suspendre l'activation MIMS du projet pour passer en mode developpement |
| `/mims resume` | Activer MIMS temporairement pour cette session |
| `/mims persist` | Reactiver MIMS de facon persistante dans le projet |
| `/mims detach` | Supprimer l'entree MIMS au niveau du projet |

Une fois la conception terminee et le projet passe en developpement, utilisez `/mims pause` pour suspendre l'activation MIMS du projet. Cela ne desinstalle pas MIMS et ne supprime pas `domain-model.yaml`, `srs.md`, `sdd.md` ni `prototype/`. Utilisez `/mims resume` pour une session temporaire ou `/mims persist` pour reactiver l'activation persistante.

## Fichiers generes

| Fichier | Description |
|---|---|
| `domain-model.yaml` | Modele de domaine et progression |
| `srs.md` | Document d'exigences |
| `sdd.md` | Document de conception |
| `prototype/` | Prototype consultable dans le navigateur |

## Cas d'usage

MIMS convient aux systemes de gestion, workflows, outils internes, systemes de type CRM/ERP et validation initiale de produit. Les prototypes generes servent a la revue et a la communication, pas au deploiement en production.

## Licence

MIT License
