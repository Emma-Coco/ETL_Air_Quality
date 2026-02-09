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
for pod in $(kubectl get pods -n air-quality --no-headers | grep -v "Running\|Completed" | awk '{print $1}'); do
    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Pod: $pod${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo -e "\n${BLUE}Description :${NC}"
    kubectl describe pod $pod -n air-quality | tail -30
    
    echo -e "\n${BLUE}Logs :${NC}"
    kubectl logs $pod -n air-quality --tail=50 2>&1 || echo "Pas de logs disponibles"
done

echo -e "\n${BLUE}📋 État des déploiements :${NC}"
kubectl get deployments -n air-quality

echo -e "\n${BLUE}🔧 État des services :${NC}"
kubectl get svc -n air-quality

echo -e "\n${BLUE}💾 État des volumes :${NC}"
kubectl get pvc -n air-quality

echo -e "\n${BLUE}⚙️  ConfigMap :${NC}"
kubectl get configmap -n air-quality

echo -e "\n${BLUE}🔐 Secrets :${NC}"
kubectl get secret -n air-quality

echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}💡 Commandes utiles :${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Voir les logs d'un pod backend :"
echo "  kubectl logs -n air-quality deployment/air-quality-backend"
echo ""
echo "Voir les événements :"
echo "  kubectl get events -n air-quality --sort-by='.lastTimestamp'"
echo ""
echo "Redémarrer un déploiement :"
echo "  kubectl rollout restart deployment air-quality-backend -n air-quality"
echo ""
