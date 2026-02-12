#!/bin/bash

echo "🛑 Arrêt de l'application Air Quality ETL..."
echo ""

docker compose down

echo ""
echo "✅ Application arrêtée"
echo ""
echo "💡 Pour supprimer également les données :"
echo "   docker compose down -v"
echo ""
