#!/bin/bash

# Déterminer le répertoire racine du projet
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🛑 Arrêt de l'application Air Quality ETL..."
echo ""

docker compose down

echo ""
echo "✅ Application arrêtée"
echo ""
echo "💡 Pour supprimer également les données :"
echo "   docker compose down -v"
echo ""