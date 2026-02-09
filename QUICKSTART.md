# 🚀 Quickstart — Air Quality ETL

## Démarrage rapide (30 secondes)

```bash
# 1. Cloner et entrer dans le projet
cd ETL_Air_Quality

# 2. Lancer avec le script automatique
./start.sh

# 3. Ouvrir le navigateur
open http://localhost
```

**C'est tout !** ✨

---

## Commandes essentielles

### Démarrage

```bash
# Automatique (recommandé)
./start.sh

# Manuel
docker compose up --build
```

### Arrêt

```bash
# Avec le script
./stop.sh

# Manuel
docker compose down
```

### Logs

```bash
# Tous les services
docker compose logs -f

# Backend uniquement
docker compose logs -f api

# Frontend uniquement
docker compose logs -f frontend
```

### Redémarrage

```bash
# Tout redémarrer
docker compose restart

# Un service spécifique
docker compose restart api
```

---

## 🌐 URLs importantes

| Service | URL | Description |
|---------|-----|-------------|
| 🖥️ **Dashboard** | http://localhost | Interface utilisateur |
| 🔧 **API Docs** | http://localhost:8000/docs | Documentation Swagger |
| ❤️ **Health** | http://localhost:8000/health | Vérification de l'état |

---

## 📊 Charger les données

```bash
# Via curl (terminal)
curl -X POST http://localhost:8000/load

# Via Swagger UI (navigateur)
# 1. Aller sur http://localhost:8000/docs
# 2. Trouver POST /load
# 3. Cliquer "Try it out" → "Execute"
```

---

## 🛠️ Commandes utiles

```bash
# Voir les conteneurs actifs
docker compose ps

# Voir les volumes
docker volume ls

# Entrer dans un conteneur
docker compose exec api bash
docker compose exec frontend sh

# Supprimer tout (conteneurs + volumes)
docker compose down -v

# Rebuild complet
docker compose build --no-cache
docker compose up
```

---

## 🐛 Problèmes courants

### Le dashboard ne charge pas les données

```bash
# Solution : Charger les données
curl -X POST http://localhost:8000/load
```

### Port déjà utilisé

```bash
# Trouver le processus
lsof -i :80
lsof -i :8000

# Ou changer le port dans docker-compose.yml
# Exemple : "8080:80" au lieu de "80:80"
```

### Docker daemon non actif

```bash
# Démarrer Docker Desktop manuellement
# Vérifier avec :
docker info
```

### Conteneurs ne démarrent pas

```bash
# Voir les logs d'erreur
docker compose logs

# Rebuild propre
docker compose down
docker compose build --no-cache
docker compose up
```

---

## 📚 Documentation

- **Guide complet** : [DOCKER_GUIDE.md](DOCKER_GUIDE.md)
- **Résumé Phase 3** : [PHASE3_SUMMARY.md](PHASE3_SUMMARY.md)
- **Changements** : [CHANGES.md](CHANGES.md)
- **README** : [README.md](README.md)

---

## 🧪 Tests rapides

```bash
# Test 1 : API accessible
curl http://localhost:8000/health
# Attendu : {"status":"ok"}

# Test 2 : Frontend accessible
curl -I http://localhost
# Attendu : HTTP/1.1 200 OK

# Test 3 : Données disponibles
curl http://localhost:8000/air-quality/daily
# Attendu : Tableau JSON avec des données

# Test 4 : Proxy fonctionnel
curl http://localhost/api/health
# Attendu : {"status":"ok"}
```

---

## 🎯 Endpoints principaux

### ETL

```bash
GET  /extract           # Données brutes Open-Meteo
GET  /transform         # Données transformées
GET  /aggregate-daily   # Agrégation quotidienne
POST /load              # Chargement en base
```

### Lecture

```bash
GET /air-quality/today        # Données du jour
GET /air-quality/daily?limit=5 # N derniers jours
GET /health                    # Health check
```

---

## 💡 Tips

1. **Logs en temps réel** : `docker compose logs -f`
2. **Rebuild rapide** : `docker compose up --build -d`
3. **Nettoyage complet** : `docker compose down -v && docker system prune -a`
4. **Backup DB** : `docker cp air-quality-api:/app/air_quality.db ./backup.db`
5. **Restore DB** : `docker cp ./backup.db air-quality-api:/app/air_quality.db`

---

## 📞 Besoin d'aide ?

1. Consultez [DOCKER_GUIDE.md](DOCKER_GUIDE.md) pour des explications détaillées
2. Vérifiez les logs : `docker compose logs -f`
3. Testez l'API directement : http://localhost:8000/docs

---

**Version** : Phase 3 - Février 2026  
**Statut** : ✅ Production-ready
