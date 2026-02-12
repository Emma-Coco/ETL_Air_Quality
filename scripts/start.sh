#!/bin/bash

set -e

# Déterminer le répertoire racine du projet (un niveau au-dessus de /scripts)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🚀 Démarrage de l'application Air Quality ETL..."
echo ""

# Vérifier que Docker est actif
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker daemon n'est pas actif."
    echo "   Veuillez démarrer Docker Desktop et réessayer."
    exit 1
fi

echo "✅ Docker daemon actif"
echo ""

# Build et démarrage
echo "📦 Build des images Docker..."
docker compose build

echo ""
echo "🎬 Démarrage des services..."
docker compose up -d

echo ""
echo "⏳ Attente du démarrage des services (10s)..."
sleep 10

# Vérifier que les services sont actifs
echo ""
echo "🔍 Vérification des services..."

if docker compose ps | grep -q "air-quality-api"; then
    echo "✅ Backend (API) : actif"
else
    echo "❌ Backend (API) : problème de démarrage"
    docker compose logs api
    exit 1
fi

if docker compose ps | grep -q "air-quality-frontend"; then
    echo "✅ Frontend : actif"
else
    echo "❌ Frontend : problème de démarrage"
    docker compose logs frontend
    exit 1
fi

# Test de l'API
echo ""
echo "🧪 Test de l'API..."
if curl -s http://localhost:8000/health | grep -q "ok"; then
    echo "✅ API backend : accessible"
else
    echo "⚠️  API backend : non accessible (peut nécessiter quelques secondes supplémentaires)"
fi

# Chargement des données
echo ""
echo "📊 Chargement des données initiales..."
LOAD_RESULT=$(curl -s -X POST http://localhost:8000/load)

if echo "$LOAD_RESULT" | grep -q "success"; then
    echo "✅ Données chargées avec succès"
    echo "   $LOAD_RESULT"
else
    echo "⚠️  Problème lors du chargement des données"
    echo "   Vous pouvez réessayer manuellement : curl -X POST http://localhost:8000/load"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Application démarrée avec succès !"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📍 Accès :"
echo "   🌐 Dashboard   : http://localhost"
echo "   🔧 API Docs    : http://localhost:8000/docs"
echo "   ❤️  Health Check: http://localhost:8000/health"
echo ""
echo "📝 Commandes utiles :"
echo "   • Voir les logs      : docker compose logs -f"
echo "   • Arrêter           : docker compose down"
echo "   • Redémarrer        : docker compose restart"
echo ""
echo "📚 Documentation complète : voir docs/DOCKER_GUIDE.md"
echo ""