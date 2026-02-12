#!/bin/bash

echo "🔍 Diagnostic du déploiement Kubernetes"
echo "======================================="
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📊 État des pods :${NC}"
kubectl get pods -n air-quality

echo -e "\n${BLUE}🔍 Détails des pods en erreur :${NC}"
# On cherche les pods qui ne sont pas en Running ou Completed
ERROR_PODS=$(kubectl get pods -n air-quality --no-headers | grep -v "Running\|Completed" | awk '{print $1}')

if [ -z "$ERROR_PODS" ]; then
    echo -e "${GREEN}Aucun pod en erreur détecté.${NC}"
else
    for pod in $ERROR_PODS; do
        echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}Pod en difficulté: $pod${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        echo -e "\n${BLUE}Derniers événements :${NC}"
        kubectl describe pod $pod -n air-quality | grep -A 10 "Events:"
        
        echo -e "\n${BLUE}Derniers logs (si disponibles) :${NC}"
        kubectl logs $pod -n air-quality --tail=20 2>&1 || echo "Pas de logs disponibles."
    done
fi

echo -e "\n${BLUE}📋 État des déploiements :${NC}"
kubectl get deployments -n air-quality

echo -e "\n${BLUE}🔧 État des services :${NC}"
kubectl get svc -n air-quality

echo -e "\n${BLUE}💾 État des volumes :${NC}"
kubectl get pvc -n air-quality

echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}💡 Commandes de secours :${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Voir les logs du backend :"
echo "  kubectl logs -n air-quality deployment/air-quality-backend"
echo ""
echo "Redémarrer les services :"
echo "  kubectl rollout restart deployment -n air-quality"
echo ""