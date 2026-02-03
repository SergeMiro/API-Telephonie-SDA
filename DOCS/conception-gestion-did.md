# Projet de Gestion Centralisée des DID

**Document de Conception Validé**
Date : 03 février 2026 (mis à jour)
Statut : Validé en réunion d'équipe

### Évolutions du 03/02/2026
- Ajout de la table **TEL_REGION** pour indiquer la région géographique des SDA
- Ajout des statuts **"Commandé"** et **"Disponible"**
- Ajout du module de **demande de commande de SDA** (TEL_DID_COMMANDE)

---

## 1. Contexte et Objectifs

### Problématique actuelle
La gestion des numéros de téléphone (DID - Direct Inward Dialing) est actuellement dispersée et manque de traçabilité centralisée.

### Objectifs du projet
- **Centraliser** la gestion de tous les numéros de téléphone Fimainfo
- **Tracer** l'affectation des numéros aux clients et campagnes
- **Automatiser** la configuration des redirections d'appels Hermes
- **Simplifier** l'administration via une interface extranet

---

## 2. Architecture des Données

### 2.1 Schéma Relationnel

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              BASE DE DONNÉES                                 │
│                      FIMLONSQL2.HN_FIMAINFO_CONFIG                          │
└─────────────────────────────────────────────────────────────────────────────┘

                              TABLES DE RÉFÉRENCE
    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │  INDICATIF   │  │  OPERATEUR   │  │   TYPE_DID   │  │  EQUIPEMENT  │
    ├──────────────┤  ├──────────────┤  ├──────────────┤  ├──────────────┤
    │ id (PK)      │  │ id (PK)      │  │ id (PK)      │  │ id (PK)      │
    │ code (FR,BE) │  │ nom          │  │ libelle      │  │ nom          │
    │ libelle      │  │ (Bouygues,   │  │ (NPV,Mobile, │  │ (SBC,Centrex,│
    │              │  │  Telnyx...)  │  │  Régional)   │  │  T2,Astra)   │
    └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
           │                 │                 │                 │
           │    ┌────────────┴────────────┐    │                 │
           │    │         REGION          │    │                 │
           │    ├─────────────────────────┤    │                 │
           │    │ id (PK)                 │    │                 │
           │    │ indicatif_id (FK)       │    │                 │
           │    │ code (IDF,PACA,NOR...)  │    │                 │
           │    │ libelle                 │    │                 │
           │    │ prefixe (01,04,03...)   │    │                 │
           │    └────────────┬────────────┘    │                 │
           │                 │                 │                 │
           ▼                 ▼                 ▼                 ▼
    ┌─────────────────────────────────────────────────────────────────────┐
    │                              DID                                     │
    │                    (Table principale des numéros)                    │
    ├─────────────────────────────────────────────────────────────────────┤
    │  id (PK)           │ Identifiant unique                             │
    │  indicatif_id (FK) │ → INDICATIF                                    │
    │  did               │ Numéro 9 chiffres                              │
    │  did_format_e164   │ Format international (+33...)                  │
    │  operateur_id (FK) │ → OPERATEUR                                    │
    │  type_id (FK)      │ → TYPE_DID                                     │
    │  region_id (FK)    │ → REGION (nouveau)                             │
    │  client_id (FK)    │ → CLIENT                                       │
    │  groupement_id(FK) │ → GROUPEMENT                                   │
    │  equipement_id(FK) │ → EQUIPEMENT                                   │
    │  statut_id (FK)    │ → STATUT_DID                                   │
    │  cloud_id (FK)     │ → CLOUD                                        │
    │  description       │ Texte libre + région automatique               │
    └─────────────────────────────────────────────────────────────────────┘
           │                 ▲                 ▲                 ▲
           │                 │                 │                 │
           │    ┌────────────┴──┐  ┌──────────┴───┐  ┌─────────┴────┐
           │    │    CLIENT     │  │  GROUPEMENT  │  │  STATUT_DID  │
           │    ├───────────────┤  ├──────────────┤  ├──────────────┤
           │    │ id (PK)       │  │ id (PK)      │  │ id (PK)      │
           │    │ nom           │  │ client_id FK │  │ libelle      │
           │    │  ..           │  │ libelle      │  │ (Résilié,    │
           │    │               │  │ (Admin,      │  │  Affecté,    │
           │    │               │  │  Production) │  │  Utilisé)    │
           │    └───────────────┘  └──────────────┘  └──────────────┘
           │
           │    ┌──────────────┐
           │    │    CLOUD     │
           │    ├──────────────┤
           │    │ id (PK)      │
           │    │ nom          │
           |    | routage      |
           │    └──────────────┘
           │
           ▼
    ┌─────────────────────────────────────────────────────────────────────┐
    │                          DID_VIRTUAL                                │
    │              (Table d'affectation aux campagnes Hermes)             │
    ├─────────────────────────────────────────────────────────────────────┤
    │  id (PK)           │ Identifiant unique                             │
    │  did               │ → DID (numéro réel)                            │
    │  campaign_id (FK)  │ → CAMPAIGN (campagne Hermes)                   │
    │  config_id (FK)    │ → DID_CONFIG (paramètres JSON)                 │
    └─────────────────────────────────────────────────────────────────────┘
           │                              │
           ▼                              ▼
    ┌──────────────┐              ┌──────────────────────────────────────┐
    │   CAMPAIGN   │              │            DID_CONFIG                │
    ├──────────────┤              ├──────────────────────────────────────┤
    │ id (PK)      │              │ id (PK)                              │
    │ nom          │              │ config (JSON)                        │
    │ ...          │              │   - nom_site                         │
    │              │              │   - couleur                          │
    │              │              │   - logo                             │
    │              │              │   - paramètres personnalisés         │
    └──────────────┘              └──────────────────────────────────────┘
```

---

### 2.2 Description des Tables

#### Tables de Référence (Lookup Tables)

| Table | Description | Exemples de valeurs |
|-------|-------------|---------------------|
| `INDICATIF` | Indicatifs pays | FR, BE, EN, CH... |
| `OPERATEUR` | Opérateurs télécom | Bouygues, Telnyx, Twilio, Orange... |
| `TYPE_DID` | Types de numéros | NPV, Mobile, Régionalisé, Géographique |
| `EQUIPEMENT` | Équipements de routage | SBC, Centrex, T2, Astra |
| `STATUT_DID` | États des numéros | Commandé, Disponible, Affecté, Utilisé, Résilié |
| `REGION` | Régions géographiques | IDF, PACA, NOR, NES, SES, SOU... |
| `CLOUD` | Environnements cloud | (À définir selon infrastructure) |
| `GROUPEMENT` | Sous-entités client | Administration, Production, Support... |

#### Tables Principales

| Table | Rôle | Usage |
|-------|------|-------|
| `DID` | Inventaire central | Gestion interne Fimainfo de tous les numéros |
| `DID_VIRTUAL` | Affectation campagnes | Configuration Hermes pour redirections appels |
| `DID_CONFIG` | Paramétrage JSON | Personnalisation par numéro (branding, options) |

---

### 2.3 Définition des Statuts

| Statut | Code | Description | Couleur |
|--------|------|-------------|---------|
| **Commandé** | COMMANDE | Numéro en cours de commande auprès de l'opérateur | 🟠 Orange |
| **Disponible** | DISPONIBLE | Numéro disponible sur le client, non affecté à une campagne | 🔵 Bleu |
| **Affecté** | AFFECTE | Numéro attribué à un client mais non utilisé actuellement | 🟡 Jaune |
| **Utilisé** | UTILISE | Numéro en production active | 🟢 Vert |
| **Résilié** | RESILIE | Numéro non actif, libéré ou en cours de résiliation | 🔴 Rouge |

### 2.4 Table REGION (Nouvelle)

| Champ | Description |
|-------|-------------|
| `id` | Identifiant unique |
| `indicatif_id` | Lien vers le pays (FR, BE...) |
| `code` | Code région (IDF, PACA, NOR...) |
| `libelle` | Nom complet (Île-de-France, PACA...) |
| `prefixe` | Préfixe téléphonique (01, 04, 03...) |

### 2.5 Module Commande de SDA (Nouveau)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          TEL_DID_COMMANDE                                   │
│                    (Demandes de commande de numéros)                        │
├─────────────────────────────────────────────────────────────────────────────┤
│  id (PK)              │ Identifiant unique                                  │
│  reference            │ Référence unique (CMD-2026-00001)                   │
│  client_id (FK)       │ → CLIENT demandeur                                  │
│  type_did_id (FK)     │ → TYPE_DID souhaité                                 │
│  region_id (FK)       │ → REGION souhaitée (optionnel)                      │
│  quantite             │ Nombre de numéros demandés                          │
│  urgence              │ BASSE, NORMALE, HAUTE, URGENTE                      │
│  statut_id (FK)       │ → STATUT_COMMANDE                                   │
│  demandeur_*          │ Informations du demandeur                           │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────┐
│  STATUT_COMMANDE     │
├──────────────────────┤
│ BROUILLON            │
│ SOUMISE              │
│ VALIDEE              │
│ EN_COURS             │
│ LIVREE               │
│ REJETEE              │
│ ANNULEE              │
└──────────────────────┘
```

#### Workflow de Commande

```
[Création] → BROUILLON → SOUMISE → VALIDEE → EN_COURS → LIVREE
                  ↓           ↓
              ANNULEE     REJETEE
```

---

## 3. Flux de Données

### 3.1 Appels Entrants
```
Appel entrant → DID_VIRTUAL → Campaign Hermes → Redirection configurée
                                      ↓
              DID_CONFIG (paramètres d'affichage)
```

### 3.2 Appels Sortants
```
Campaign Hermes → DID_VIRTUAL → DID (numéro affiché)
```

---

## 4. Plan de Réalisation

### Phase 1 : Base de Données
**Objectif** : Création des structures de données

| Action | Base cible |
|--------|------------|
| Création tables de référence | FIMLONSQL2.HN_FIMAINFO_CONFIG |
| Création table DID | FIMLONSQL2.HN_FIMAINFO_CONFIG |
| Création table DID_VIRTUAL | FIMLONSQL2.HN_FIMAINFO_CONFIG |
| Création table DID_CONFIG | FIMLONSQL2.HN_FIMAINFO_CONFIG |

### Phase 2 : API
**Objectif** : Développement de l'API REST

| Composant | Description |
|-----------|-------------|
| Nom | API_TELEPHONY |
| Opérations | CRUD complet sur toutes les tables |
| Authentification | À définir (JWT, API Key...) |

### Phase 3 : Interface Extranet
**Objectif** : Interface d'administration

| Élément | Localisation |
|---------|--------------|
| Module | admin/telephony |
| Fonctionnalités | Gestion complète des DID via l'API |

### Phase 4 : Migration et Intégration
**Objectif** : Mise en production

| Action | Impact |
|--------|--------|
| Migration données DID_VIRTUAL existantes | Reprise de l'historique |
| Mise à jour configuration Hermes | Fichiers : recept.ons, S2.ons, etc. |

---

## 5. Synthèse des Livrables

| # | Livrable | Description | Statut |
|---|----------|-------------|--------|
| 1 | **Scripts SQL** | Création des tables dans HN_FIMAINFO_CONFIG | ✅ Créé |
| 2 | **API_TELEPHONY** | API REST CRUD | 🔲 À faire |
| 3 | **Module Extranet** | Interface admin/telephony | 🔲 À faire |
| 4 | **Module Commande** | Interface de demande de SDA | 🔲 À faire |
| 5 | **Scripts Migration** | Migration des données existantes | 🔲 À faire |
| 6 | **Config Hermes** | Mise à jour des fichiers .ons | 🔲 À faire |

### Scripts SQL Créés

| Fichier | Description |
|---------|-------------|
| `00_install_all.sql` | Script principal d'installation |
| `01_tables_reference.sql` | Tables de référence (INDICATIF, OPERATEUR, TYPE_DID, etc.) |
| `02_table_did.sql` | Table principale TEL_DID |
| `03_tables_virtual_config.sql` | Tables TEL_DID_VIRTUAL et TEL_DID_CONFIG |
| `04_table_commande.sql` | Tables de gestion des commandes |
| `05_indexes.sql` | Index pour optimisation des performances |
| `06_views.sql` | Vues SQL pour l'API |

---

## 6. Bénéfices Attendus

- **Centralisation** : Un seul point de vérité pour tous les DID
- **Traçabilité** : Historique complet des affectations
- **Automatisation** : Configuration Hermes automatisée
- **Simplicité** : Interface unifiée pour l'administration
- **Évolutivité** : Structure extensible pour futurs besoins

---

## 7. Prochaines Étapes

1. Validation direction
2. Création des scripts SQL
3. Développement API_TELEPHONY
4. Intégration extranet
5. Tests et recette
6. Migration et mise en production

---
