# MIMS - Make Idea Make Sense

> **Rendre les idées raisonnables, claires et réalisables**

---

## Apercu du Projet

MIMS est un Agent AI qui prend la forme du « Guide MIMS » (迷悟师), guidant les utilisateurs non techniques a travers la conception logicielle via un dialogue proactif a plusieurs tours, aidant a transformer des idees vagues en modeles de domaine clairs et en prototypes interactifs.

MIMS est deploye pour Claude Code CLI, compose de trois composants principaux : la configuration de persona injectee dans l'Agent principal (`CLAUDE.md`), le workflow structure (Skill), et les sous-agents traitant les taches atomiques.

### Concept Principal

**Make Idea Make Sense** - A travers un dialogue structure et une assistance AI, aider les utilisateurs a transformer leurs idees en prototypes :

- **Rendre les idees claires** - Transformer des exigences vagues en concepts organises et comprehensibles
- **Rendre les idees visibles** - Visualiser et concretiser les concepts abstraits
- **Rendre les idees realisables** - Transformer les idees en prototypes interactifs

### Utilisateurs Cibles

- **Chefs de Produit** - Valider rapidement les idees de produits
- **Analystes d'Affaires** - Exprimer clairement les exigences metier
- **Entrepreneurs** - Planifier des MVP (Produits Minimums Viables)
- **Experts du Domaine** - Concevoir des logiciels sans bagage technique

### Caracteristiques Cles

1. **Aucune Barriere Technique** - Conversation en langage courant, aucun outil a apprendre
2. **Guidage AI Proactif** - L'Agent pose des questions de maniere proactive pour clarifier les exigences
3. **Generation Automatique de Modeles** - Construction automatique de modeles d'objets de domaine a partir du dialogue
4. **Visualisation Instantanee** - Affichage en temps reel des changements de modele et des relations
5. **Prototypes Interactifs** - Generation de prototypes fonctionnant directement dans les navigateurs

---

## Signification du Nom

**MIMS** = **M**ake **I**dea **M**ake **S**ense

**Prononciation** : /mɪmz/

**Nom Complet** : Make Idea Make Sense

- **Make** - Creer, construire, rendre... quelque chose
- **Idea** - Idee, concept, exigence, inspiration
- **Make Sense** - Devenir raisonnable, clair, organise, comprehensible

---

## Fonctionnement

```
┌─────────────────────────────────────────────────────────────┐
│                    Boucle de Dialogue MIMS                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  L'utilisateur presente une idee/exigence                   │
│         ↓                                                   │
│  L'Agent AI pose des questions (clarifier, affiner)         │
│         ↓                                                   │
│  L'utilisateur repond                                       │
│         ↓                                                   │
│  L'agent met a jour automatiquement le modele de domaine    │
│         ↓                                                   │
│  Afficher le modele pour confirmation par l'utilisateur     │
│         ↓                                                   │
│  Retour/confirmation de l'utilisateur                       │
│         ↓                                                   │
│  La boucle continue jusqu'a ce que le modele soit clair     │
│         ↓                                                   │
│  Generer un prototype interactif                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Framework de Modelisation** : MIMS adopte le framework **FBS (Function-Behavior-Structure)**, une ontologie classique en sciences du design (Gero, 1990), qui correspond egalement fortement aux trois types de diagrammes UML (Cas d'utilisation/Etat/Classe).

| Couche FBS | Questions Cles | Etape de Dialogue |
|-----------|---------------|-------------------|
| **F Fonction** | Qui l'utilise ? Quels scenarios ? Quelles taches ? | Analyse des roles et scenarios |
| **B Comportement** | Quels etats ? Comment operer ? Quelles regles ? | Modelisation des etats et operations |
| **S Structure** | Que gerer ? Quelles informations ? Comment liees ? | Modelisation des objets et relations metier |

> Ordre de dialogue : descendant (F→B→S), sortie du modele : ordre de dependance (S→B→F).

---

## Architecture Technique

```
Couche Dialogue        Couche Donnees        Couche Generation       Couche Documentation
CLAUDE.md              Modele YAML           Prototype HTML/JS       Documents Markdown
+ Skill
+ Sous-agents
```

### Stack Technologique

| Couche | Technologie | Justification |
|--------|------------|---------------|
| Persona & Comportement de Base | CLAUDE.md | Injection T0 dans l'Agent principal, toujours actif |
| Workflow de Dialogue | AI CLI Skill | Chargement a la demande, declencheurs standardises |
| Taches Prototype/Validation | AI CLI Sous-agents | Isolation des taches atomiques, pas de pollution du contexte |
| Stockage des Donnees | YAML | Lisible par l'humain, adapte a l'AI |
| Generation de Prototypes | HTML/CSS/JS | Zero dependances, fonctionne directement dans les navigateurs |
| Sortie Documentation | Markdown | Facile a lire, facile a versionner |

---

## Structure des Documents

```
MIMS/
├── README.md                           # Ce document
├── CLAUDE.md                           # Guide d'implementation du projet (auto-charge par Claude Code)
├── impl/                               # Fichiers d'implementation deployables
│   ├── README.md                       # Instructions d'installation (inclut le guidage AI)
│   ├── CLAUDE.md                       # Persona MIMS (Claude Code, injection T0)
│   └── .claude/
│       ├── agents/
│       │   ├── mims-validator.md       # Sous-agent de validation de modele (4 modes)
│       │   ├── mims-prototyper.md      # Sous-agent de generation de prototype
│       │   ├── mims-change-manager.md  # Sous-agent de gestion des changements
│       │   └── mims-spec-generator.md  # Sous-agent de generation de documents SRS/SDD
│       └── skills/mims/
│           ├── SKILL.md                # Workflow de modelisation des exigences & generation de prototype
│           └── references/             # Base de connaissances (a la demande)
│               ├── schema.md           # Schema Core §1-5
│               ├── schema-examples.md  # Jeux de donnees d'exemple (a la demande)
│               ├── persona-rules.md    # Regles de persona et de dialogue
│               ├── claude-md-template.md # Modele CLAUDE.md pour projet utilisateur
│               ├── prompt-ref.md       # Modeles de prompts (reference developpeur)
│               ├── iteration-rules.md  # Regles d'iteration de conception
│               ├── workflow-common.md  # Mecanismes communs inter-phases
│               ├── workflow-preliminary.md  # Conception preliminaire P1-P6
│               ├── workflow-detailed.md     # Conception detaillee D1-D5
│               ├── workflow-prototype.md    # Generation de prototype R1-R9
│               ├── srs-template.md     # Modele de document SRS
│               └── sdd-template.md     # Modele de document SDD
│
└── docs/                               # Tous les documents de conception
    ├── core/                           # Specifications de conception principales
    │   ├── DESIGN.md                   # Decisions et principes de conception
    │   └── PERSONA.md                  # Persona de l'Agent AI
    │
    ├── progress/                       # Progression et analyse
    │   └── PROJECT_PROGRESS.md         # Rapport d'avancement du projet
    │
    └── archive/                        # Documents archives (reference historique)
```

## Guide de Lecture

| Si vous voulez... | Lecture recommandee |
|-------------------|-------------------|
| Comprendre ce qu'est le projet | `README.md` (ce document) |
| Comprendre les decisions de conception | `docs/core/DESIGN.md` |
| Comprendre les specifications de comportement de l'Agent | `docs/core/PERSONA.md` |
| Voir le workflow complet | `impl/.claude/skills/mims/SKILL.md` + `references/` |
| Comprendre la gestion des changements | `references/iteration-rules.md` |
| Voir les definitions du Schema | `references/schema.md` + `references/schema-examples.md` |

---

## Trois Phases

### Phase 1 : Conception Preliminaire

Completee par dialogue (6 etapes) :
1. **P1 Collecte et Preparation des Exigences** - Comprendre les idees initiales, guider la preparation des documents
2. **P2 Comprehension des Documents** (optionnel) - Analyser les documents fournis par l'utilisateur
3. **P3 Contexte et Objectifs** - Comprendre le contexte metier et les objectifs generaux
4. **P4 Roles et Scenarios** - Definir les roles utilisateurs et les cas d'utilisation (plusieurs-a-plusieurs)
5. **P5 Processus Metier** - Cartographier les processus principaux (montes sur scenarios, flux d'information)
6. **P6 Apercu de l'Architecture** - Division en modules, interfaces externes, evaluation de l'Agent AI

**Point de controle** : Validation preliminaire → generer `srs.md`

**Sortie** : `domain-model.yaml` (couche F + modules) + `srs.md` (Specification des Exigences Logicielles)

### Phase 2 : Conception Detaillee

Modelisation approfondie (5 etapes) :
1. **D1 Reconnaissance des Objets Metier** - Extraire les choses a gerer et leurs attributs
2. **D2 Relations et Attribution aux Modules** - Definir les relations, l'attribution aux modules, la conception de l'Agent AI
3. **D3 Etats et Cycle de Vie** - Definir les etats des objets et les conditions de transition
4. **D4 Operations et Regles Metier** - Definir les operations et les regles metier
5. **D5 Validation du Modele et Confiance** - Valider la completude du modele, evaluer la confiance

**Point de controle** : Validation complete → generer `sdd.md`

**Sortie** : `domain-model.yaml` (FBS complet) + `sdd.md` (Document de Conception Logicielle)

### Phase 3 : Generation de Prototype

Generee a partir du modele (9 etapes) :
1. **R1 Analyse du Modele** - Analyser les caracteristiques des donnees du modele
2. **R2 Permissions des Pages** - Attribuer les permissions par role
3. **R3 Mappage des Fonctions** - Mapper les operations aux fonctions de page
4. **R4 Conception des Flux** - Concevoir la navigation et les flux de pages
5. **R5 Structure des Pages** - Recommander la mise en page selon les caracteristiques des donnees
6. **R6 Interaction des Pages** - Determiner les modes d'interaction
7. **R7 Generation de Code** - Generer HTML/CSS/JS (delegue au prototyper)
8. **R8 Validation des Processus** - Validation de bout en bout avec les processus metier
9. **R9 Livraison** - Livrer le prototype, guider l'expérience

**Sortie** : `prototype/` (prototype interactif avec workbench piloté par les processus et conseils d'expérience intégrés)

### Gestion des Processus

- **Reprise** : Continuer a partir du dernier point de controle apres interruption
- **Iteration de Conception** : Supporter les modifications pendant la conception et apres la livraison du prototype, avec evaluation automatique de l'impact
- **Niveaux de Changement** : L1 ajustement mineur → L4 changement majeur, chacun avec une portee de retour en arriere differente

---

## Concepts Cles (Langage Non Technique)

| Couche FBS | Terme Technique | Notre Terme | Exemple |
|-----------|----------------|-------------|---------|
| F Fonction | Acteur | Role Utilisateur | Administrateur, Acheteur, Client |
| F Fonction | Scenario | Cas d'Utilisation | Pointage quotidien, Inventaire mensuel |
| F Fonction | Processus | Processus Metier | Processus complet de la commande a la livraison |
| S Structure | Objet Metier | Choses a gerer | Client, Commande, Produit |
| S Structure | Attribut | Information/Champ | Nom, Telephone, Quantite |
| S Structure | Relation | Association/Lien | Le client « a » plusieurs commandes |
| B Comportement | Etat | Statut Actuel | En attente de paiement, Expedia |
| B Comportement | Operation | Action Disponible | Approuver, Expedier, Annuler |
| B Comportement | Regle Metier | Contrainte | Seuls les administrateurs peuvent approuver |

---

## Principes de Conception

1. **Utilisateur d'Abord** - Les besoins et la comprehension de l'utilisateur priment sur la perfection technique
2. **Divulgation Progressive** - Approfondir graduellement, eviter la surcharge d'informations
3. **Retour Instantane** - Afficher les resultats immediatement apres chaque etape
4. **Transparent et Controllable** - L'utilisateur controle toujours la direction du dialogue
5. **Tracabilite** - Enregistrer toutes les decisions et modifications

---

## Standards de Qualite

### Completude
- ✅ Tous les champs obligatoires sont remplis
- ✅ Attributs d'entite ≥ 2
- ✅ Relations clairement definies
- ✅ Les operations principales ont des regles metier

### Coherence
- ✅ Conventions de nommage unifiees
- ✅ Pas de dependances circulaires
- ✅ Pas de regles metier conflictuelles

### Confiance
- 90%-100% : Excellent - Passer a l'etape suivante
- 70%-90% : Bon - Demander s'il faut continuer
- 50%-70% : Moyen - Recommander une clarification supplementaire
- <50% : Faible - Doit resoudre les problemes cles

---

## Gestion des Changements

Les modifications sont supportees a la fois pendant la conception et apres la livraison du prototype. Voir `references/iteration-rules.md` pour plus de details.

Supporte 4 niveaux de changement :

| Niveau | Type | Exemple | Traitement |
|--------|------|---------|-----------|
| L1 | Ajustement Mineur | Modifier le nom d'affichage | Modification directe a l'etape actuelle |
| L2 | Modification Partielle | Modifier le type d'attribut | Retour a l'etape concernee |
| L3 | Changement Moyen | Ajouter une nouvelle entite | Retour au debut de la phase |
| L4 | Changement Majeur | Supprimer une entite | Retour a la conception preliminaire ou creer un nouveau projet |

**Avant changement** : Afficher l'analyse d'impact
**Apres changement** : Valider la coherence, synchroniser le modele et le prototype

---

## Demarrage Rapide

### Installation et Utilisation

Pour les instructions completes d'installation, de mise a jour, de verification et d'utilisation, voir **[`impl/README.md`](impl/README.md)**.

Experience rapide :

```bash
cd /your-project
curl -sSL https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install.sh | bash  # Linux/macOS
# Windows PowerShell:
# iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install.ps1'))
```

### En tant qu'Utilisateur

1. **Preparer** - Avoir une idee ou une exigence initiale
2. **Demarrer** - Appeler la commande `/mims design`
3. **Conception Preliminaire** - Repondre aux questions du Guide (P1-P6)
4. **Conception Detaillee** - Approfondir les objets, etats et regles (D1-D5)
5. **Generer un Prototype** - Generer le prototype a partir du modele (R1-R9)
6. **Iterer** - Ajuster la conception selon les retours (`/mims change`)
7. **Valider** - Visualiser le prototype dans le navigateur

### En tant que Developpeur

**Lire la Documentation** :
- Comprendre l'architecture du projet et le deploiement depuis `CLAUDE.md`
- Comprendre les decisions de conception depuis `docs/core/DESIGN.md`
- Comprendre le persona et le comportement de l'Agent depuis `docs/core/PERSONA.md`
- Comprendre le workflow complet depuis `impl/.claude/skills/mims/SKILL.md` + `references/`

**Deploiement** :
- **Recommande** : Utiliser le script d'installation (voir `impl/README.md`), qui gere automatiquement les fichiers de compatibilite Codex
- **Manuel** : Copier le contenu du repertoire `impl/` a la racine du projet ; creation supplementaire de `AGENTS.md` et `.agents/` requise (voir methode 2 dans `impl/README.md`)
- **Agent AI** : Les agents AI ne doivent PAS copier directement `impl/` ; telecharger et executer le script d'installation (voir methode 3 dans `impl/README.md`)

---

## Philosophie de Conception

MIMS s'inspire des methodologies et concepts suivants :

- **Ontologie FBS (Gero, 1990)** - Function-Behavior-Structure, fondation theorique du framework de modelisation
- **UML (Unified Modeling Language)** - Diagrammes de cas d'utilisation (couche F), diagrammes de classes (couche S), diagrammes d'etats (couche B)
- **Domain-Driven Design (DDD)** - Objets de domaine, agregats, evenements de domaine
- **Harness Engineering (2026)** - Systeme de contraintes d'Agent pilote par la qualite
- **User Story Mapping** - Analyse des exigences pilotee par les scenarios
- **Conversational Design** - Design d'interaction en langage naturel

Voir : `docs/core/DESIGN.md`

---

## Contraintes Techniques

| Contrainte | Impact | Attenuation |
|------------|--------|------------|
| Longueur du Contexte | Les longs dialogues peuvent depasser les limites | Chargement segmente, persistance de fichiers |
| Concurrence de Fichiers | Conflits multi-sessions | Mecanisme de verrouillage de fichiers |
| Complexite du Prototype | HTML/JS ne peut pas implementer la logique backend | Clarifier les limites du prototype |
| Compatibilite de Version | Changements de format YAML | Gestion des numeros de version |

---

## Licence et Attribution

Ce projet est un depot de documents de conception decrivant la philosophie de conception, l'architecture technique et les specifications d'implementation de l'outil MIMS (Make Idea Make Sense).

**Date de Creation** : 2026-03-21
**Version Actuelle** : v1.4
**Statut** : Conception et implementation terminees

---

## Contact et Retours

Les questions et suggestions sont les bienvenues !

---

**Rendre les idees claires, rendre les idees visibles, rendre les idees realisables.**
