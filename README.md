# Air Quality ETL — Docker & Kubernetes

### Description du projet

Ce projet met en œuvre un pipeline ETL (Extract – Transform – Load) permettant de collecter, transformer et stocker des données de qualité de l’air à partir d’une API publique.
L’application est exposée sous forme d’API REST, conteneurisée avec Docker et déployée via Kubernetes afin de démontrer des notions d’orchestration et de résilience.

## Source des données

Les données proviennent de l’API publique Open-Meteo – Air Quality, qui fournit des mesures et prévisions horaires de polluants atmosphériques.

Polluants utilisés :

PM2.5

PM10

Dioxyde d’azote (NO₂)

Les données sont récupérées sous forme horaire, puis agrégées quotidiennement.

## Pipeline ETL

### Extract

L’extraction consiste à appeler l’API Open-Meteo afin de récupérer les données horaires de pollution pour une localisation donnée (latitude / longitude).

Endpoint :

GET /extract

### Transform

Les données horaires sont regroupées par date afin de calculer :

la moyenne journalière de PM2.5

la moyenne journalière de PM10

la moyenne journalière de NO₂

Cette étape permet de réduire le volume de données et de produire une information plus exploitable.

Endpoint :

GET /aggregate-daily

### Load

Les données agrégées sont stockées dans une base SQLite sous forme de moyennes journalières.
Chaque appel au chargement enrichit progressivement l’historique en base, selon la fenêtre temporelle fournie par l’API.

Endpoint :

POST /load


### Structure de la table :

date (clé primaire)

pm2_5_avg

pm10_avg

nitrogen_dioxide_avg

## Base de données

Le projet utilise SQLite, choix volontairement simple et adapté au cadre d’un TP.
La base contient uniquement les données agrégées journalières, et non les données horaires brutes.

## Architecture technique

API Open-Meteo
      ↓
FastAPI (ETL)
      ↓
SQLite


L’API FastAPI expose les différents endpoints ETL et sert de point d’entrée unique pour le traitement des données.

## Docker

L’application est conteneurisée avec Docker afin de garantir :

la reproductibilité de l’environnement

l’isolation des dépendances

la portabilité de l’application

Docker permet de construire une image contenant l’application et son environnement d’exécution.

## Kubernetes

L’application est déployée sur un cluster Kubernetes local via Docker Desktop.

Deployment

Le Deployment définit l’état souhaité de l’application :

image Docker à utiliser

nombre de Pods (instances)

redémarrage automatique en cas de panne

Pod

Un Pod correspond à une instance de l’application FastAPI en cours d’exécution.

Service

Le Service fournit un point d’accès réseau stable vers l’application, indépendamment des Pods sous-jacents, et permet la répartition du trafic.

## Résilience

La résilience est assurée par Kubernetes :

si un Pod est supprimé ou tombe en panne

Kubernetes recrée automatiquement une nouvelle instance

le Service continue de rediriger les requêtes

Cette propriété a été testée en supprimant manuellement un Pod.

## Lancement du projet

Docker
docker build -t air-quality-api .
docker run -p 8000:8000 air-quality-api

Docker Compose
docker-compose up --build

Kubernetes
kubectl apply -f deploy/


Accès à l’API :

http://localhost:30080/health

## Conclusion

Ce projet illustre la mise en place complète d’un pipeline ETL simple mais réaliste, déployé dans un environnement conteneurisé et orchestré.
Il met en évidence les apports de Docker pour la portabilité et de Kubernetes pour la gestion du cycle de vie et la résilience de l’application.