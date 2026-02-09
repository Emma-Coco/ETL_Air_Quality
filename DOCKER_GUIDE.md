# Docker Setup Guide - Air Quality ETL

## Architecture

```
┌─────────────────────────────────────────┐
│         Docker Compose                  │
│                                         │
│  ┌──────────────┐   ┌───────────────┐  │
│  │   Frontend   │   │    Backend    │  │
│  │   (nginx)    │◄──│   (FastAPI)   │  │
│  │   Port 80    │   │   Port 8000   │  │
│  └──────────────┘   └───────────────┘  │
│         │                    │          │
│         │            ┌───────▼─────┐    │
│         │            │  SQLite DB  │    │
│         │            │  (volume)   │    │
│         │            └─────────────┘    │
└─────────────────────────────────────────┘
```

## Structure des fichiers

```
.
├── backend/
│   ├── Dockerfile          # Image Python 3.11 + FastAPI
│   ├── .dockerignore       # Exclusions de build
│   ├── requirements.txt    # Dépendances Python
│   └── app/
│       └── main.py         # API FastAPI
├── frontend/
│   ├── Dockerfile          # Image nginx Alpine
│   ├── .dockerignore       # Exclusions de build
│   ├── nginx.conf          # Configuration nginx avec proxy API
│   ├── index.html          # Dashboard HTML
│   ├── scripts.js          # Logique frontend
│   └── style.css           # Styles CSS
└── docker-compose.yml      # Orchestration complète
```

## Docker Compose - Services

### Service `api` (Backend)

- **Image** : Python 3.11 slim
- **Port** : 8000 (exposé sur localhost:8000)
- **Volume** : `air-quality-data:/app` (persistence de la base SQLite)
- **Health check** : Test du endpoint `/health` toutes les 30s
- **Réseau** : `air-quality-network` (bridge)

### Service `frontend` (Frontend)

- **Image** : Nginx Alpine
- **Port** : 80 (exposé sur localhost:80)
- **Proxy** : Les requêtes vers `/api/*` sont proxifiées vers `api:8000/*`
- **Dépendance** : Attend que le service `api` soit démarré
- **Réseau** : `air-quality-network` (bridge)

## Lancement de l'application

### 1. Démarrer Docker Desktop

Assurez-vous que Docker Desktop est lancé et que le daemon Docker est actif.

Vérification :
```bash
docker info
```

### 2. Build et lancement

```bash
# Build et démarrage des deux services
docker compose up --build

# En mode détaché (arrière-plan)
docker compose up --build -d
```

### 3. Accès à l'application

| Service | URL | Description |
|---------|-----|-------------|
| **Dashboard** | http://localhost | Interface utilisateur complète |
| **API Docs** | http://localhost:8000/docs | Documentation Swagger interactive |
| **Health Check** | http://localhost:8000/health | Vérification de l'état du backend |

### 4. Chargement initial des données

La base de données SQLite est vide au premier lancement. Pour charger les données :

```bash
# Via curl
curl -X POST http://localhost:8000/load

# Via le navigateur (Swagger UI)
# Allez sur http://localhost:8000/docs
# Trouvez l'endpoint POST /load
# Cliquez sur "Try it out" puis "Execute"
```

Réponse attendue :
```json
{
  "status": "success",
  "rows_inserted": 7
}
```

### 5. Utilisation du dashboard

1. Ouvrez http://localhost dans votre navigateur
2. Le dashboard affiche :
   - La qualité de l'air du jour (PM2.5, PM10, NO₂)
   - Un tableau des 5 derniers jours
   - Un graphique d'évolution temporelle

**Note** : Si aucune donnée n'apparaît, assurez-vous d'avoir exécuté l'étape 4 (chargement des données).

## Commandes utiles

### Gestion des conteneurs

```bash
# Voir les logs
docker compose logs

# Logs en temps réel
docker compose logs -f

# Logs d'un service spécifique
docker compose logs -f api
docker compose logs -f frontend

# Arrêter les services
docker compose down

# Arrêter et supprimer les volumes
docker compose down -v

# Redémarrer un service
docker compose restart api
docker compose restart frontend
```

### Inspection

```bash
# Voir les conteneurs actifs
docker compose ps

# Voir les réseaux
docker network ls

# Voir les volumes
docker volume ls

# Inspecter le volume de données
docker volume inspect etl_air_quality_air-quality-data

# Entrer dans un conteneur
docker compose exec api bash
docker compose exec frontend sh
```

### Debug

```bash
# Vérifier les logs du backend
docker compose logs api

# Tester l'API manuellement
curl http://localhost:8000/health
curl http://localhost:8000/air-quality/daily

# Vérifier la configuration nginx
docker compose exec frontend cat /etc/nginx/conf.d/default.conf

# Voir les processus dans le conteneur
docker compose exec api ps aux
docker compose exec frontend ps aux
```

## Endpoints de l'API

### ETL Pipeline

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/extract` | Récupère les données horaires brutes depuis Open-Meteo |
| GET | `/transform` | Transforme les données horaires en format structuré |
| GET | `/aggregate-daily` | Agrège les données par jour (moyennes) |
| POST | `/load` | Charge les données agrégées dans SQLite |

### Data Access

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/air-quality/daily?limit=5` | Récupère les N derniers jours |
| GET | `/air-quality/today` | Récupère les données du jour |
| GET | `/health` | Health check |

## Résolution de problèmes

### Le frontend ne se connecte pas au backend

**Symptôme** : Dashboard affiche "Loading..." indéfiniment

**Solutions** :
1. Vérifiez que les deux conteneurs sont actifs : `docker compose ps`
2. Vérifiez les logs du backend : `docker compose logs api`
3. Testez l'API directement : `curl http://localhost:8000/health`
4. Chargez les données : `curl -X POST http://localhost:8000/load`

### Erreur "port already in use"

**Symptôme** : `bind: address already in use`

**Solutions** :
```bash
# Trouver le processus utilisant le port 80
lsof -i :80

# Trouver le processus utilisant le port 8000
lsof -i :8000

# Ou modifier les ports dans docker-compose.yml
# Exemple : "8080:80" pour le frontend
```

### Base de données vide après redémarrage

**Cause** : Le volume Docker a été supprimé

**Solution** :
```bash
# Rechargez les données
curl -X POST http://localhost:8000/load
```

### Erreur de build

**Symptôme** : Échec lors de `docker compose up --build`

**Solutions** :
```bash
# Nettoyer les builds précédents
docker compose down
docker system prune -a

# Rebuild complet
docker compose build --no-cache
docker compose up
```

## Données persistées

Les données SQLite sont stockées dans un volume Docker nommé `air-quality-data`.

```bash
# Localisation du volume
docker volume inspect etl_air_quality_air-quality-data

# Backup du volume
docker run --rm -v etl_air_quality_air-quality-data:/data \
  -v $(pwd):/backup alpine \
  tar czf /backup/air-quality-backup.tar.gz -C /data .

# Restore du volume
docker run --rm -v etl_air_quality_air-quality-data:/data \
  -v $(pwd):/backup alpine \
  tar xzf /backup/air-quality-backup.tar.gz -C /data
```

## Configuration nginx

Le frontend utilise nginx comme serveur web et reverse proxy :

```nginx
# Servir les fichiers statiques sur /
location / {
    root /usr/share/nginx/html;
    index index.html;
}

# Proxifier /api/* vers http://api:8000/*
location /api/ {
    proxy_pass http://api:8000/;
    # ... headers de proxy ...
}
```

Cette configuration permet au frontend d'appeler `/api/health` qui est automatiquement transféré vers `http://api:8000/health` dans le réseau Docker.

## Réseau Docker

Les deux services communiquent via un réseau bridge nommé `air-quality-network`.

Dans ce réseau :
- Le backend est accessible via le nom `api` (nom du service)
- Le frontend est accessible via le nom `frontend`
- Les ports internes sont utilisés (8000, 80), pas les ports externes

## Production Considerations

⚠️ **Cette configuration est adaptée pour un TP / développement local.**

Pour une utilisation en production, considérez :

1. **Sécurité**
   - Désactiver CORS wildcard dans FastAPI
   - Ajouter HTTPS (certificat SSL)
   - Configurer des variables d'environnement pour les secrets
   - Utiliser un gestionnaire de secrets (Docker secrets, Vault)

2. **Base de données**
   - Migrer vers PostgreSQL ou MySQL pour la production
   - Implémenter des backups automatiques
   - Configurer la réplication

3. **Performance**
   - Ajouter un cache Redis
   - Configurer des limits de ressources (CPU, mémoire)
   - Mettre en place un load balancer si plusieurs instances

4. **Monitoring**
   - Ajouter des logs structurés
   - Intégrer Prometheus + Grafana
   - Configurer des alertes

5. **CI/CD**
   - Automatiser les builds Docker
   - Implémenter des tests automatiques
   - Déployer via Kubernetes (voir `/deploy`)

## Next Steps

1. ✅ **Phase 3 complète** : Docker backend + frontend fonctionnel
2. 📊 Ajouter des graphiques avancés (Chart.js)
3. 🌍 Support multi-villes (Paris, Lyon, Marseille...)
4. 🔄 Automatiser le refresh des données (cronjob)
5. ☸️ Déploiement Kubernetes avec Helm charts
6. 🚀 CI/CD avec GitHub Actions
