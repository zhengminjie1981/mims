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

> Dialogue order: top-down (F→B→S), model output: dependency order (S→B→F).

---

## Technical Architecture

```
Dialogue Layer       Data Layer       Generation Layer       Documentation Layer
CLAUDE.md            YAML Model       HTML/JS Prototype      Markdown Docs
+ Skill
+ Sub-agents
```

### Technology Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| Persona & Base Behavior | CLAUDE.md | T0 injection into main Agent, always active |
| Dialogue Workflow | AI CLI Skill | On-demand loading, standardized triggers |
| Prototype/Validation Tasks | AI CLI Sub-agents | Atomic task isolation, no context pollution |
| Data Storage | YAML | Human-readable, AI-friendly |
| Prototype Generation | HTML/CSS/JS | Zero dependencies, runs directly in browsers |
| Documentation Output | Markdown | Easy to read, easy to version control |

---

## Document Structure

```
MIMS/
├── README.md                           # This document
├── CLAUDE.md                           # Project implementation guide (auto-loaded by Claude Code)
├── impl/                               # Deployable implementation files
│   ├── README.md                       # Installation instructions (includes AI agent guidance)
│   ├── CLAUDE.md                       # MIMS persona (Claude Code, T0 injection)
│   └── .claude/
│       ├── agents/
│       │   ├── mims-validator.md       # Model validation sub-agent (4 modes)
│       │   ├── mims-prototyper.md      # Prototype generation sub-agent
│       │   ├── mims-change-manager.md  # Change management sub-agent
│       │   └── mims-spec-generator.md  # SRS/SDD document generation sub-agent
│       └── skills/mims/
│           ├── SKILL.md                # Requirements modeling & prototype generation workflow
│           └── references/             # Knowledge base (on-demand)
│               ├── schema.md           # Core Schema §1-5
│               ├── schema-examples.md  # Example datasets (on-demand)
│               ├── persona-rules.md    # Persona and dialogue rules
│               ├── claude-md-template.md # User project CLAUDE.md template
│               ├── prompt-ref.md       # Prompt templates (developer reference)
│               ├── iteration-rules.md  # Design iteration rules
│               ├── workflow-common.md  # Cross-phase common mechanisms
│               ├── workflow-preliminary.md  # Preliminary design P1-P6
│               ├── workflow-detailed.md     # Detailed design D1-D5
│               ├── workflow-prototype.md    # Prototype generation R1-R9
│               ├── srs-template.md     # SRS document template
│               └── sdd-template.md     # SDD document template
│
└── docs/                               # All design documents
    ├── core/                           # Core design specifications
    │   ├── DESIGN.md                   # Design decisions and principles
    │   └── PERSONA.md                  # AI Agent persona
    │
    ├── progress/                       # Progress and analysis
    │   └── PROJECT_PROGRESS.md         # Project progress report
    │
    └── archive/                        # Archived documents (historical reference)
```

## Reading Guide

| If you want to... | Recommended reading |
|-------------------|-------------------|
| Understand what the project is | `README.md` (this document) |
| Understand design decisions | `docs/core/DESIGN.md` |
| Understand Agent behavior specs | `docs/core/PERSONA.md` |
| View complete workflow | `impl/.claude/skills/mims/SKILL.md` + `references/` |
| Understand change handling | `references/iteration-rules.md` |
| View Schema definitions | `references/schema.md` + `references/schema-examples.md` |

---

## Three Phases

### Phase 1: Preliminary Design

Completed through dialogue (6 steps):
1. **P1 Requirements Collection & Preparation** - Understand initial ideas, guide material preparation
2. **P2 Material Understanding** (optional) - Analyze user-provided materials
3. **P3 Context & Goals** - Understand business background and overall objectives
4. **P4 Roles & Scenarios** - Define user roles and use cases (many-to-many)
5. **P5 Business Processes** - Map core processes (scenario-mounted, information flow)
6. **P6 Architecture Overview** - Module division, external interfaces, AI Agent evaluation

**Checkpoint**: Preliminary validation → generate `srs.md`

**Output**: `domain-model.yaml` (F layer + modules) + `srs.md` (Software Requirements Specification)

### Phase 2: Detailed Design

In-depth modeling (5 steps):
1. **D1 Business Object Recognition** - Extract things to manage and their attributes
2. **D2 Relationships & Module Assignment** - Define relationships, module assignment, AI Agent design
3. **D3 State & Lifecycle** - Define object states and transition conditions
4. **D4 Operations & Business Rules** - Define operations and business rules
5. **D5 Model Validation & Confidence** - Validate model completeness, assess confidence

**Checkpoint**: Full validation → generate `sdd.md`

**Output**: `domain-model.yaml` (complete FBS) + `sdd.md` (Software Design Document)

### Phase 3: Prototype Generation

Generated from model (9 steps):
1. **R1 Model Analysis** - Analyze model data characteristics
2. **R2 Page Permissions** - Assign page permissions by role
3. **R3 Page Function Mapping** - Map operations to page functions
4. **R4 Page Flow Design** - Design navigation and page flows
5. **R5 Page Structure** - Recommend layout based on data characteristics
6. **R6 Page Interaction** - Determine interaction patterns
7. **R7 Code Generation** - Generate HTML/CSS/JS (delegated to prototyper)
8. **R8 Process Validation** - End-to-end validation with business processes
9. **R9 Delivery** - Deliver prototype, guide user experience

**Output**: `prototype/` (interactive prototype with process-driven workbench and page experience tips)

### Process Management

- **Resume**: Continue from last checkpoint after interruption
- **Design Iteration**: Support changes during design and after prototype delivery, with automatic impact assessment
- **Change Levels**: L1 minor adjustment → L4 major change, each with different rollback scope

---

## Core Concepts (Non-Technical Language)

| FBS Layer | Technical Term | Our Term | Example |
|-----------|---------------|----------|---------|
| F Function | Actor | User Role | Admin, Purchaser, Customer |
| F Function | Scenario | Use Case | Daily check-in, Monthly inventory |
| F Function | Process | Business Process | Full process from order to delivery |
| S Structure | Business Object | Things to manage | Customer, Order, Product |
| S Structure | Attribute | Information/Field | Name, Phone, Quantity |
| S Structure | Relationship | Association/Link | Customer "has" multiple Orders |
| B Behavior | State | Current Status | Pending payment, Shipped |
| B Behavior | Operation | Available Action | Approve, Ship, Cancel |
| B Behavior | Business Rule | Constraint | Only admins can approve |

---

## Design Principles

1. **User First** - User needs and understanding take priority over technical perfection
2. **Progressive Disclosure** - Gradual depth, avoid information overload
3. **Instant Feedback** - Show results immediately after each step
4. **Transparent & Controllable** - User always controls the dialogue direction
5. **Traceable** - Record all decisions and changes

---

## Quality Standards

### Completeness
- ✅ All required fields are filled
- ✅ Entity attributes ≥ 2
- ✅ Relationships clearly defined
- ✅ Core operations have business rules

### Consistency
- ✅ Unified naming conventions
- ✅ No circular dependencies
- ✅ No conflicting business rules

### Confidence
- 90%-100%: Excellent - Proceed to next step
- 70%-90%: Good - Ask whether to proceed
- 50%-70%: Fair - Recommend further clarification
- <50%: Low - Must resolve key issues

---

## Change Management

Changes are supported both during design and after prototype delivery. See `references/iteration-rules.md` for details.

Supports 4 levels of change:

| Level | Type | Example | Handling |
|-------|------|---------|----------|
| L1 | Minor Adjustment | Change display name | Modify directly in current step |
| L2 | Partial Modification | Change attribute type | Revert to related step |
| L3 | Moderate Change | Add new entity | Revert to phase start |
| L4 | Major Change | Delete entity | Revert to preliminary design or create new project |

**Before change**: Show impact analysis
**After change**: Validate consistency, sync model and prototype

---

## Quick Start

### Installation & Usage

For complete installation, update, verification, and usage instructions, see **[`impl/README.md`](impl/README.md)**.

Quick experience:

```bash
cd /your-project
curl -sSL https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install.sh | bash  # Linux/macOS
# Windows PowerShell:
# iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install.ps1'))
```

### As a User

1. **Prepare** - Have an initial idea or requirement
2. **Start** - Call `/mims design` command
3. **Preliminary Design** - Answer the Guide's questions (P1-P6)
4. **Detailed Design** - Deep-dive into objects, states, and rules (D1-D5)
5. **Generate Prototype** - Generate prototype from model (R1-R9)
6. **Iterate** - Adjust design based on feedback (`/mims change`)
7. **Validate** - View prototype in browser

### As a Developer

**Read Documentation**:
- Understand project architecture and deployment from `CLAUDE.md`
- Understand design decisions from `docs/core/DESIGN.md`
- Understand Agent persona and behavior from `docs/core/PERSONA.md`
- Understand complete workflow from `impl/.claude/skills/mims/SKILL.md` + `references/`

**Deployment**:
- **Recommended**: Use installation script (see `impl/README.md`), which automatically handles Codex compatibility files
- **Manual**: Copy contents of `impl/` directory to project root; requires additional creation of `AGENTS.md` and `.agents/` (see Method 2 in `impl/README.md`)
- **AI Agent**: AI agents should NOT directly copy `impl/`; instead download and execute the installation script (see Method 3 in `impl/README.md`)

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

This project is a design document repository describing the design philosophy, technical architecture, and implementation specifications of the MIMS (Make Idea Make Sense) tool.

**Created**: 2026-03-21
**Current Version**: v1.4
**Status**: Design and implementation complete

---

## Contact and Feedback

Questions and suggestions are welcome!

---

**Make ideas clear, make ideas visible, make ideas actionable.**
