# MIMS - Make Idea Make Sense

> **Making ideas reasonable, clear, and actionable**

---

## Project Overview

MIMS is an AI Agent that takes the form of "迷悟师" (MIMS Guide), guiding non-technical users through software design via proactive multi-turn dialogue, helping transform vague ideas into clear domain models and interactive prototypes.

MIMS is deployed for Claude Code CLI users, consisting of three core components: persona configuration injected into the main Agent (`CLAUDE.md`), structured workflow (Skill), and sub-agents handling atomic tasks.

### Core Concept

**Make Idea Make Sense** - Through structured dialogue and AI assistance, help users transform ideas into prototypes:

- **Make Ideas Clear** - Transform vague requirements into organized, understandable concepts
- **Make Ideas Visible** - Visualize and concretize abstract concepts
- **Make Ideas Actionable** - Transform ideas into interactive prototypes

### Target Users

- **Product Managers** - Quickly validate product ideas
- **Business Analysts** - Clearly express business requirements
- **Entrepreneurs** - Plan MVPs (Minimum Viable Products)
- **Domain Experts** - Design software without technical background

### Key Features

1. **Zero Technical Barrier** - Conversational in everyday language, no tools to learn
2. **AI-Driven Guidance** - Agent proactively asks questions to clarify requirements
3. **Automatic Model Generation** - Automatically builds domain object models from dialogue
4. **Instant Visualization** - Real-time display of model changes and relationships
5. **Interactive Prototypes** - Generate prototypes that run directly in browsers

---

## Name Meaning

**MIMS** = **M**ake **I**dea **M**ake **S**ense

**Pronunciation**: /mɪmz/

**Full Name**: Make Idea Make Sense

- **Make** - Create, build, make... become
- **Idea** - Thought, concept, requirement, inspiration
- **Make Sense** - Become reasonable, clear, organized, understandable

---

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                     MIMS Dialogue Loop                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  User presents idea/requirement                             │
│         ↓                                                   │
│  AI Agent asks questions (clarify, refine, complete)        │
│         ↓                                                   │
│  User responds                                              │
│         ↓                                                   │
│  Agent automatically updates domain model                   │
│         ↓                                                   │
│  Display model for user confirmation                        │
│         ↓                                                   │
│  User feedback/confirmation                                 │
│         ↓                                                   │
│  Loop continues until model is clear and complete           │
│         ↓                                                   │
│  Generate interactive prototype                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Modeling Framework**: MIMS adopts the **FBS (Function-Behavior-Structure)** framework, a classic ontology in design science (Gero, 1990), which also corresponds highly to the three core UML diagram types (Use Case/State/Class diagrams).

| FBS Layer | Core Questions | Dialogue Stage |
|-----------|---------------|----------------|
| **F Function** | Who uses it? What scenarios? What tasks? | Role & Scenario Analysis |
| **B Behavior** | What states? How to operate? What rules? | State & Operation Modeling |
| **S Structure** | What to manage? What information? How related? | Business Object & Relationship Modeling |

> Dialogue order: top-down (F→B→S), model output: dependency order (S→B→F)

---

## Quick Start

### One-Line Installation

**Recommended for all users**:

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

**Installation Process**:
1. After running the script, select installation method:
   - **Option 1: Automatic Download (Recommended)** - Automatically download and install from GitHub
   - **Option 2: Manual Download** - Manually download zip from GitLab/GitHub, then provide path
2. Script installs files to **current directory**
3. Ready to use after completion

**Enterprise Intranet Users**: If GitHub is inaccessible, use **Option 2** to manually download zip from GitLab.

For detailed installation guide, see: [install/README.md](install/README.md)

### Getting Started

```bash
# 1. Navigate to project directory
cd /your-project

# 2. Start Claude Code
claude

# 3. Enter command to begin
/mims
```

---

## How to Use

### As a User

1. **Prepare** - Have an initial idea or requirement
2. **Start** - Call `/mims design` command
3. **Dialogue** - Answer the Guide's questions (Phase 1: Requirements Modeling)
4. **Confirm** - Review and validate the generated domain model
5. **Iterate** - Adjust until satisfied (`/mims change`)
6. **Generate Prototype** - Generate prototype from model (Phase 2, `/mims prototype`)
7. **Validate** - View prototype in browser

### As a Developer

**Read Documentation**:
- Understand overall architecture from `docs/spec/SKILL_SPEC.md`
- Understand design decisions from `docs/core/DESIGN.md`
- Understand Agent persona and behavior from `docs/core/PERSONA.md`

**Deployment**:
- **Recommended**: Use one-line installation commands above
- **Manual**: Copy contents of `impl/` directory to project root
- See `impl/README.md` for details

---

## Design Philosophy

MIMS draws from the following methodologies and concepts:

- **FBS Ontology (Gero, 1990)** - Function-Behavior-Structure, theoretical foundation for modeling framework
- **UML (Unified Modeling Language)** - Use case diagrams (F layer), class diagrams (S layer), state diagrams (B layer)
- **Domain-Driven Design (DDD)** - Domain objects, aggregates, domain events
- **Harness Engineering (2026)** - Quality-driven Agent constraint system
- **User Story Mapping** - Scenario-driven requirements analysis
- **Conversational Design** - Natural language interaction design

See: `docs/core/DESIGN.md`

---

## Technical Constraints

| Constraint | Impact | Mitigation |
|------------|--------|-----------|
| Context Length | Long dialogues may exceed limits | Segment loading, file persistence |
| File Concurrency | Multi-session conflicts | File locking mechanism |
| Prototype Complexity | HTML/JS cannot implement backend logic | Clear prototype boundaries |
| Version Compatibility | YAML format changes | Version number management |

---

## License and Attribution

**License**: Enterprise Internal Use Only

**Development Team**: XYI Tech AI Team

**Acknowledgments**:
- Claude Code CLI by Anthropic
- FBS Framework by John S. Gero
- Domain-Driven Design by Eric Evans

---

## Related Links

- **GitHub**: https://github.com/zhengminjie1981/mims
- **Documentation**: See `docs/` directory
- **Issue Reporting**: Submit via GitHub Issues

---

**Make Idea Make Sense** - Let AI help you transform ideas into reality 🚀
