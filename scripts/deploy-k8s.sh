#!/bin/bash

set -e

echo "🚀 Déploiement Air Quality ETL sur Kubernetes"
echo "=============================================="

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Déterminer le répertoire racine du projet
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Vérifier si on est dans le dossier k8s ou à la racine
if [[ "$SCRIPT_DIR" == */k8s ]]; then
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    K8S_DIR="$SCRIPT_DIR"
else
    PROJECT_ROOT="$SCRIPT_DIR"
    K8S_DIR="$SCRIPT_DIR/k8s"
fi

echo -e "${YELLOW}📁 Répertoire du projet: $PROJECT_ROOT${NC}"
echo -e "${YELLOW}📁 Répertoire K8s: $K8S_DIR${NC}"
echo ""

# Vérifier que les dossiers existent
if [ ! -d "$PROJECT_ROOT/backend" ]; then
    echo -e "${RED}❌ Erreur: dossier backend/ introuvable${NC}"
    echo "Structure attendue:"
    echo "  ."
    echo "  ├── backend/       (Dockerfile + main.py)"
    echo "  ├── frontend/      (Dockerfile + nginx.conf)"
    echo "  └── k8s/           (manifestes K8s)"
    exit 1
fi

if [ ! -d "$PROJECT_ROOT/frontend" ]; then
    echo -e "${RED}❌ Erreur: dossier frontend/ introuvable${NC}"
    exit 1
fi

if [ ! -d "$K8S_DIR" ]; then
    echo -e "${RED}❌ Erreur: dossier k8s/ introuvable${NC}"
    exit 1
fi

# Vérifier que kubectl est installé
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl n'est pas installé${NC}"
    echo "Installez kubectl : https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

echo -e "${GREEN}✅ kubectl installé : $(kubectl version --client --short 2>/dev/null || kubectl version --client)${NC}"
echo ""

# 1. Build des images Docker
echo -e "\n${BLUE}📦 Build des images Docker...${NC}"
echo -e "${YELLOW}Backend...${NC}"
docker build -t air-quality-api:latest "$PROJECT_ROOT/backend"

echo -e "${YELLOW}Frontend...${NC}"
docker build -t air-quality-frontend:latest "$PROJECT_ROOT/frontend"

echo -e "${GREEN}✅ Images Docker créées${NC}"

# Pour Minikube: charger les images dans Minikube
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    echo -e "\n${YELLOW}🔧 Minikube détecté - Chargement des images...${NC}"
    minikube image load air-quality-api:latest
    minikube image load air-quality-frontend:latest
    echo -e "${GREEN}✅ Images chargées dans Minikube${NC}"
fi

# 2. Création du namespace
echo -e "\n${BLUE}📁 Création du namespace...${NC}"
kubectl apply -f "$K8S_DIR/namespace.yaml"

# 3. Déploiement des ressources
echo -e "\n${BLUE}⚙️  Déploiement ConfigMap et Secret...${NC}"
kubectl apply -f "$K8S_DIR/configmap.yaml"
kubectl apply -f "$K8S_DIR/secret.yaml"

echo -e "\n${BLUE}💾 Création du volume persistant...${NC}"
kubectl apply -f "$K8S_DIR/pvc.yaml"

echo -e "\n${BLUE}🔧 Déploiement Backend...${NC}"
kubectl apply -f "$K8S_DIR/backend-deployment.yaml"
kubectl apply -f "$K8S_DIR/backend-service.yaml"

echo -e "\n${BLUE}🌐 Déploiement Frontend...${NC}"
kubectl apply -f "$K8S_DIR/frontend-deployment.yaml"
kubectl apply -f "$K8S_DIR/frontend-service.yaml"

# 4. Attente du démarrage
echo -e "\n${YELLOW}⏳ Attente du démarrage des pods...${NC}"
echo -e "${YELLOW}Cela peut prendre 1-2 minutes...${NC}"

kubectl wait --for=condition=ready pod \
  -l app=air-quality,component=backend \
  -n air-quality \
  --timeout=120s && echo -e "${GREEN}✅ Backend prêt${NC}" || echo -e "${YELLOW}⚠️  Timeout backend (vérifiez les logs)${NC}"

kubectl wait --for=condition=ready pod \
  -l app=air-quality,component=frontend \
  -n air-quality \
  --timeout=120s && echo -e "${GREEN}✅ Frontend prêt${NC}" || echo -e "${YELLOW}⚠️  Timeout frontend (vérifiez les logs)${NC}"

# 5. Affichage du statut
echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Déploiement terminé !${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${BLUE}📊 État du cluster :${NC}"
kubectl get all -n air-quality

echo -e "\n${BLUE}💾 Volumes :${NC}"
kubectl get pvc -n air-quality

echo -e "\n${BLUE}⚙️  ConfigMaps :${NC}"
kubectl get configmap -n air-quality

echo -e "\n${BLUE}🔐 Secrets :${NC}"
kubectl get secret -n air-quality

# 6. URLs d'accès
echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\n${GREEN}🌐 Accès à l'application :${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    echo -e "\n${YELLOW}📍 Minikube détecté${NC}"
    echo -e "Frontend : ${GREEN}$(minikube service air-quality-frontend -n air-quality --url)${NC}"
    echo -e "Backend  : ${GREEN}$(minikube service air-quality-backend -n air-quality --url)${NC}"
    echo ""
    echo -e "${BLUE}💡 Pour ouvrir le frontend automatiquement :${NC}"
    echo -e "   minikube service air-quality-frontend -n air-quality"
else
    echo -e "\n${YELLOW}📍 Docker Desktop / K8s local${NC}"
    echo -e "Frontend : ${GREEN}http://localhost:30080${NC}"
    echo -e "Backend  : ${YELLOW}kubectl port-forward -n air-quality svc/air-quality-backend 8000:8000${NC}"
    echo -e "           puis ${GREEN}http://localhost:8000/docs${NC}"
fi

# 7. Chargement initial des données
echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\n${YELLOW}📥 Chargement des données initiales...${NC}"
sleep 10

BACKEND_POD=$(kubectl get pod -n air-quality -l component=backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -n "$BACKEND_POD" ]; then
    echo -e "Pod backend trouvé : ${BLUE}$BACKEND_POD${NC}"
    
    if kubectl exec -n air-quality $BACKEND_POD -- curl -s -X POST http://localhost:8000/load &>/dev/null; then
        echo -e "${GREEN}✅ Données chargées avec succès${NC}"
    else
        echo -e "${YELLOW}⚠️  Impossible de charger les données automatiquement${NC}"
        echo -e "${YELLOW}   Chargez-les manuellement :${NC}"
        echo -e "   kubectl exec -n air-quality $BACKEND_POD -- curl -X POST http://localhost:8000/load ou kubectl run curl-debug -n air-quality --rm -it \
  --image=curlimages/curl --restart=Never \
  -- curl -X POST http://air-quality-backend:8000/load "
    fi
else
    echo -e "${YELLOW}⚠️  Aucun pod backend prêt${NC}"
    echo -e "${YELLOW}   Attendez quelques secondes puis chargez manuellement :${NC}"
    echo -e "   kubectl exec -n air-quality deployment/air-quality-backend -- curl -X POST http://localhost:8000/load"
fi

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 Déploiement Kubernetes complet !${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📚 Commandes utiles :${NC}"
echo -e "  • Voir les logs backend  : ${YELLOW}kubectl logs -n air-quality -l component=backend -f${NC}"
echo -e "  • Voir les logs frontend : ${YELLOW}kubectl logs -n air-quality -l component=frontend -f${NC}"
echo -e "  • Lister les pods        : ${YELLOW}kubectl get pods -n air-quality${NC}"
echo -e "  • Supprimer tout         : ${YELLOW}kubectl delete namespace air-quality${NC}"
echo ""
echo -e "${BLUE}📖 Documentation complète : K8S_GUIDE.md${NC}"
echo ""
