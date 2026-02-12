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

### ATTENTION

Le projet propose deux orchestrations distinctes selon l'objectif :

Développement (Docker Compose) : Idéal pour coder. Les modifications sont rapides.

Commande : ./scripts/start.sh

Production (Kubernetes) : Pour tester la haute disponibilité et la persistance réelle.

Commande : ./scripts/deploy-k8s.sh

Une fois démarrée, l'application est accessible aux adresses suivantes :

-   Dashboard interactif : http://localhost
-   Documentation API (Swagger) : http://localhost:8000/docs
-   Santé du système : http://localhost:8000/health


## Table des scripts

./scripts/start.sh	Lancement rapide (Docker Compose)
./scripts/deploy-k8s.sh	Déploiement complet sur Kubernetes
./scripts/verify.sh	Vérifie que tous les objets K8s sont créés et prêts
./scripts/diagnose.sh	Analyse les logs et les événements en cas d'erreur de Pod
./scripts/cleanup-k8s.sh	Supprime proprement le Namespace et les volumes

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


## Tests de résilience

Tests de Résilience (Kubernetes)
Une fois déployé sur Kubernetes via ./scripts/deploy-k8s.sh, vous pouvez tester l'auto-réparation du système :

Identifier le Pod Backend : kubectl get pods -n air-quality

Simuler une panne (Suppression) : kubectl delete pod <NOM_DU_POD_BACKEND> -n air-quality

Observer le Self-Healing : Le contrôleur Kubernetes détecte immédiatement l'absence du Pod et en recrée un nouveau pour maintenir l'état désiré (replicas: 1).

Vérifier la Persistance : Grâce au PersistentVolumeClaim, la base de données SQLite est conservée. Le nouveau Pod se reconnecte automatiquement au fichier /data/air_quality.db sans perte de données.

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
