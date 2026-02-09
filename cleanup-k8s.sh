#!/bin/bash

echo "🧹 Nettoyage des ressources Kubernetes Air Quality ETL..."
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Vérifier que le namespace existe
if kubectl get namespace air-quality &> /dev/null; then
    echo -e "${YELLOW}Suppression du namespace 'air-quality' et toutes ses ressources...${NC}"
    
    # Afficher ce qui va être supprimé
    echo ""
    echo -e "${YELLOW}Ressources à supprimer :${NC}"
    kubectl get all,configmap,secret,pvc -n air-quality
    
    echo ""
    read -p "Êtes-vous sûr de vouloir supprimer toutes ces ressources ? (y/N) " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl delete namespace air-quality
        echo ""
        echo -e "${GREEN}✅ Namespace 'air-quality' supprimé${NC}"
        echo -e "${GREEN}✅ Toutes les ressources ont été nettoyées${NC}"
    else
        echo -e "${YELLOW}❌ Annulation du nettoyage${NC}"
        exit 0
    fi
else
    echo -e "${RED}❌ Le namespace 'air-quality' n'existe pas${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 Nettoyage terminé !${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}💡 Pour redéployer l'application :${NC}"
echo -e "   ./deploy-k8s.sh"
echo ""
