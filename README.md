# Air Quality ETL --- Dashboard Paris

Ce projet implémente un pipeline ETL (Extract, Transform, Load) complet,
de la collecte de données environnementales jusqu'à leur visualisation
dans une interface moderne.

L'architecture repose sur des microservices conteneurisés et orchestrés
afin de garantir résilience, scalabilité et maintenabilité.

------------------------------------------------------------------------

## Quickstart (Démarrage Rapide)

Pour lancer l'application complète (Frontend + Backend + Base de
données) en une seule commande :

``` bash
# 1. Rendre les scripts exécutables
chmod +x scripts/*.sh

# 2. Lancer le script d'automatisation
./scripts/start.sh
```

Une fois démarrée, l'application est accessible aux adresses suivantes :

-   Dashboard interactif : http://localhost
-   Documentation API (Swagger) : http://localhost:8000/docs
-   Santé du système : http://localhost:8000/health

------------------------------------------------------------------------

## Architecture & Technologies

Le projet est découpé en services spécialisés communiquant via une API
REST.

### Backend --- FastAPI

-   Gestion du pipeline ETL
-   Calcul des moyennes journalières
-   Exposition des endpoints REST
-   Accès aux données SQLite

### Frontend --- Nginx Alpine

-   Interface HTML / CSS / JavaScript
-   Visualisation des données
-   Interaction avec l'API backend

### Base de données --- SQLite

-   Stockage persistant des moyennes journalières
-   Isolation dans un volume Docker
-   Protection contre la perte de données

### Infrastructure

-   Docker Compose pour l'environnement de développement
-   Kubernetes pour l'environnement cible de production

------------------------------------------------------------------------

## Le Pipeline ETL (Objectifs Pédagogiques)

Le cœur de l'application respecte les trois étapes ETL définies dans les
consignes du projet.

### 1. Extract (Extraction)

Le backend interroge l'API publique Open-Meteo afin de récupérer les
mesures horaires brutes :

-   PM2.5
-   PM10
-   NO₂

### 2. Transform (Transformation)

Les données horaires sont :

-   Nettoyées
-   Vérifiées
-   Agrégées en moyennes quotidiennes
-   Réduites aux informations pertinentes

Le traitement est réalisé en Python.

### 3. Load (Chargement)

Les données transformées sont insérées dans la base SQLite.

L'utilisation de la commande SQL suivante :

``` sql
INSERT OR REPLACE
```

garantit :

-   Absence de doublons
-   Mise à jour automatique des données existantes
-   Intégrité du stockage

### Interaction

Conformément aux exigences du TP, le frontend intègre un bouton
"Actualiser les données" permettant de déclencher manuellement le cycle
ETL complet.

------------------------------------------------------------------------

## Déploiement & Résilience (Kubernetes)

Pour l'environnement de production, le projet utilise les objets
Kubernetes suivants :

### Namespace

Isolation des ressources dans l'espace :

    air-quality

### PersistentVolumeClaim (PVC)

-   Conservation des données SQLite
-   Résistance aux redémarrages des Pods

### Liveness & Readiness Probes

-   Surveillance automatique de l'état de l'API
-   Redémarrage automatique en cas d'échec
-   Garantie de disponibilité

------------------------------------------------------------------------

## Documentation Détaillée

Des guides techniques sont disponibles dans le dossier :

    ./docs/

### Guide Docker

-   Dockerfiles
-   Réseaux
-   Gestion des volumes
-   Build et exécution

### Guide Kubernetes

-   Déploiement sur cluster
-   Tests de résilience
-   Scaling

### Historique des Phases

-   Évolution du projet
-   Choix d'architecture
-   Arbitrages techniques

------------------------------------------------------------------------

## Maintenance & Utilitaires

Des scripts sont fournis dans le dossier :

    ./scripts/

  Script                     Description
  -------------------------- -----------------------------------------
  ./scripts/start.sh         Lancement complet des services
  ./scripts/stop.sh          Arrêt propre des conteneurs
  ./scripts/verify.sh        Test de connectivité Frontend ↔ Backend
  ./scripts/cleanup-k8s.sh   Suppression des ressources Kubernetes

------------------------------------------------------------------------

## Stack Technique

-   Python
-   FastAPI
-   Docker
-   Docker Compose
-   Kubernetes
-   Nginx
-   SQLite

------------------------------------------------------------------------

## Auteur

Projet de fin de module\
Février 2026
