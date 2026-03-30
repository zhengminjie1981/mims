# MIMS - Make Idea Make Sense

> **Rendre les idées raisonnables, claires et réalisables**

---

## Aperçu du Projet

MIMS est un agent AI qui prend la forme du "Guide MIMS", guidant les utilisateurs non techniques à travers la conception logicielle via un dialogue proactif à plusieurs tours, aidant à transformer des idées vagues en modèles de domaine clairs et en prototypes interactifs.

MIMS est déployé pour les utilisateurs de Claude Code CLI, composé de trois éléments principaux : la configuration de persona injectée dans l'agent principal (`CLAUDE.md`), le workflow structuré (Skill), et les sous-agents traitant les tâches atomiques.

### Concept Principal

**Make Idea Make Sense** - À travers un dialogue structuré et une assistance AI, aider les utilisateurs à transformer leurs idées en prototypes :

- **Rendre les idées claires** - Transformer des exigences vagues en concepts organisés et compréhensibles
- **Rendre les idées visibles** - Visualiser et concrétiser les concepts abstraits
- **Rendre les idées réalisables** - Transformer les idées en prototypes interactifs

### Utilisateurs Cibles

- **Chefs de Produit** - Valider rapidement les idées de produits
- **Analystes d'Affaires** - Exprimer clairement les exigences métier
- **Entrepreneurs** - Planifier des MVP (Produits Minimums Viables)
- **Experts du Domaine** - Concevoir des logiciels sans bagage technique

### Caractéristiques Principales

1. **Aucune Barrière Technique** - Conversation en langage courant, aucun outil à apprendre
2. **Guidage AI Proactif** - L'agent pose des questions de manière proactive pour clarifier les exigences
3. **Génération Automatique de Modèles** - Construction automatique de modèles d'objets de domaine à partir du dialogue
4. **Visualisation Instantanée** - Affichage en temps réel des changements de modèle et des relations
5. **Prototypes Interactifs** - Génération de prototypes fonctionnant directement dans les navigateurs

---

## Signification du Nom

**MIMS** = **M**ake **I**dea **M**ake **S**ense

**Prononciation** : /mɪmz/

**Nom Complet** : Make Idea Make Sense

- **Make** - Créer, construire, rendre... quelque chose
- **Idea** - Idée, concept, exigence, inspiration
- **Make Sense** - Devenir raisonnable, clair, organisé, compréhensible

---

## Fonctionnement

```
┌─────────────────────────────────────────────────────────────┐
│                    Boucle de Dialogue MIMS                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  L'utilisateur présente une idée/exigence                   │
│         ↓                                                   │
│  L'agent AI pose des questions (clarifier, affiner)         │
│         ↓                                                   │
│  L'utilisateur répond                                       │
│         ↓                                                   │
│  L'agent met à jour automatiquement le modèle de domaine    │
│         ↓                                                   │
│  Afficher le modèle pour confirmation par l'utilisateur     │
│         ↓                                                   │
│  Retour/confirmation de l'utilisateur                       │
│         ↓                                                   │
│  La boucle continue jusqu'à ce que le modèle soit clair     │
│         ↓                                                   │
│  Générer un prototype interactif                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Framework de Modélisation** : MIMS adopte le framework **FBS (Function-Behavior-Structure)**, une ontologie classique en sciences du design (Gero, 1990), qui correspond également fortement aux trois types de diagrammes UML (Cas d'utilisation/État/Classe).

| Couche FBS | Questions Clés | Étape de Dialogue |
|-----------|---------------|-------------------|
| **F Fonction** | Qui l'utilise ? Quels scénarios ? Quelles tâches ? | Analyse des rôles et scénarios |
| **B Comportement** | Quels états ? Comment opérer ? Quelles règles ? | Modélisation des états et opérations |
| **S Structure** | Que gérer ? Quelles informations ? Comment liées ? | Modélisation des objets et relations métier |

> Ordre de dialogue : descendant (F→B→S), sortie du modèle : ordre de dépendance (S→B→F)

---

## Démarrage Rapide

### Installation en Une Ligne

**Méthode recommandée** (pour tous les utilisateurs):

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

**Processus d'installation**:
1. Après exécution du script, choisissez la méthode d'installation:
   - **Option 1: Téléchargement automatique (Recommandé)** - Téléchargement et installation automatiques depuis GitHub
   - **Option 2: Téléchargement manuel** - Télécharger manuellement le zip depuis GitLab/GitHub, puis fournir le chemin
2. Le script installe les fichiers dans le **répertoire courant**
3. Prêt à utiliser après l'installation

**Utilisateurs en Intranet d'Entreprise**: Si GitHub est inaccessible, utilisez **l'Option 2** pour télécharger manuellement le fichier zip depuis GitLab.

Guide d'installation détaillé: [install/README.md](install/README.md)

### Commencer

```bash
# 1. Naviguer vers le répertoire du projet
cd /your-project

# 2. Démarrer Claude Code
claude

# 3. Entrer la commande pour commencer
/mims design
```

---
- **Recommandé** : Utiliser les commandes d'installation en une ligne ci-dessus
- **Manuel** : Copier le contenu du répertoire `impl/` à la racine du projet utilisateur
- Voir `impl/README.md` pour les détails

---

## Deux Phases

### Phase 1 : Modélisation des Exigences

Complétée par dialogue (9 étapes) :
1. **Collecte des Exigences** - Comprendre les idées initiales
2. **Compréhension du Contexte** - Comprendre le contexte métier et les rôles utilisateurs
3. **Analyse des Rôles et Scénarios** - Définir les scénarios d'utilisation et les participants
4. **Cartographie des Processus Métier** - Cartographier les processus métier principaux
5. **Identification des Objets Métier** - Extraire les choses à gérer
6. **Modélisation des Relations d'Objets** - Définir les relations entre objets et l'organisation des modules
7. **Modélisation des États et Transitions** - Définir les états des objets et les conditions de transition
8. **Modélisation des Opérations et Règles** - Définir les opérations et les règles métier
9. **Validation du Modèle** - Confirmer la complétude du modèle

**Sortie** : `domain-model.yaml` (modèle d'objets de domaine)

### Phase 2 : Génération de Prototype

Généré à partir du modèle :
1. **Mappage d'Interface** - Concevoir la structure des pages
2. **Style d'Interaction** - Déterminer le format d'affichage (tableau/carte/liste)
3. **Génération de Code** - Générer HTML/CSS/JS
4. **Aperçu et Test** - Visualiser le prototype dans le navigateur
5. **Itérer et Optimiser** - Ajuster selon les retours

**Sortie** : `prototype/` (prototype interactif)

---

## Concepts Clés (Langage Non Technique)

| Couche FBS | Terme Technique | Notre Terme | Exemple |
|-----------|----------------|-------------|---------|
| F Fonction | Acteur | Rôle Utilisateur | Administrateur, Acheteur, Client |
| F Fonction | Scénario | Scénario d'Utilisation | Inventaire quotidien, Vérification mensuelle |
| F Fonction | Processus | Processus Métier | Processus complet de la commande à la livraison |
| S Structure | Objet Métier | Choses à gérer | Client, Commande, Produit |
| S Structure | Attribut | Information/Champ | Nom, Téléphone, Quantité |
| S Structure | Relation | Connexion/Lien | Le client "a" plusieurs commandes |
| B Comportement | État | Statut Actuel | En attente de paiement, Expédié |
| B Comportement | Opération | Choses que l'on peut faire | Approuver, Expédier, Annuler |
| B Comportement | Règle Métier | Contrainte | Seuls les administrateurs peuvent approuver |

---

## Principes de Conception

1. **Utilisateur d'Abord** - Les besoins et la compréhension de l'utilisateur priment sur la perfection technique
2. **Divulgation Progressive** - Approfondir graduellement, éviter la surcharge d'informations
3. **Retour Instantané** - Afficher les résultats immédiatement après chaque étape
4. **Transparent et Contrôlable** - L'utilisateur contrôle toujours la direction du dialogue
5. **Traçable** - Enregistrer toutes les décisions et modifications

---

## Standards de Qualité

### Complétude
- ✅ Tous les champs obligatoires remplis
- ✅ Attributs d'entité ≥2
- ✅ Définitions de relations claires
- ✅ Opérations principales avec règles métier

### Cohérence
- ✅ Conventions de nommage unifiées
- ✅ Pas de dépendances circulaires
- ✅ Pas de règles métier conflictuelles

### Confiance
- 90%-100% : Excellent - Recommandé de procéder
- 70%-90% : Bon - Demander si continuer
- 50%-70% : Moyen - Recommander une clarification supplémentaire
- <50% : Faible - Doit résoudre les problèmes clés

---

## Gestion des Changements

Supporte 4 niveaux de changement :

| Niveau | Type | Exemple | Traitement |
|--------|------|---------|-----------|
| L1 | Ajustement Mineur | Modifier le nom chinois | Changement direct à l'étape actuelle |
| L2 | Modification Locale | Modifier le type d'attribut | Retour à l'étape concernée |
| L3 | Changement Moyen | Ajouter une nouvelle entité | Retour au début de la phase |
| L4 | Changement Majeur | Supprimer une entité | Retour à la phase 1 ou créer un nouveau projet |

**Avant Changement** : Afficher l'analyse d'impact
**Après Changement** : Valider la cohérence

---

## Origines de la Philosophie de Conception

Ce projet s'inspire des méthodes et concepts suivants :

- **Ontologie FBS (Gero, 1990)** - Function-Behavior-Structure, fondation théorique du framework de modélisation
- **UML (Unified Modeling Language)** - Diagrammes de cas d'utilisation (couche F), diagrammes de classes (couche S), diagrammes d'états (couche B)
- **Domain-Driven Design (DDD)** - Objets de domaine, agrégats, événements de domaine
- **Harness Engineering (2026)** - Système de contraintes d'agent piloté par la qualité
- **User Story Mapping** - Analyse des exigences pilotée par les scénarios
- **Conversational Design** - Design d'interaction en langage naturel

Voir : `docs/core/DESIGN.md`

---

## Contraintes Techniques

| Contrainte | Impact | Atténuation |
|-----------|--------|------------|
| Longueur du Contexte | Les longs dialogues peuvent dépasser les limites | Chargement segmenté, persistance de fichiers |
| Concurrence de Fichiers | Sessions multiples peuvent entrer en conflit | Mécanisme de verrouillage de fichiers |
| Complexité du Prototype | HTML/JS ne peut pas implémenter la logique backend | Clarifier les limites du prototype |
| Compatibilité de Version | Changements de format YAML | Gestion des numéros de version |

---

## Licence et Attribution

Ce projet est une documentation de conception décrivant la philosophie de conception, l'architecture technique et les spécifications d'implémentation de l'outil MIMS (Make Idea Make Sense).

**Date de Création** : 2026-03-21
**Version Actuelle** : v1.1.0
**Statut de la Documentation** : Conception et implémentation terminées

---

## Contact et Retours

Des questions ou des suggestions ? N'hésitez pas à discuter !

---

**Rendre les idées claires, rendre les idées visibles, rendre les idées réalisables.**
