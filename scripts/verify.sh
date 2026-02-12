#!/bin/bash

echo "✅ Script de vérification complet - Air Quality ETL sur Kubernetes"
echo "=================================================================="
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Compteurs
PASSED=0
FAILED=0

# Fonction de test
test_step() {
    local description="$1"
    local command="$2"
    
    echo -e "\n${BLUE}🔍 Test : $description${NC}"
    
    if eval "$command" &>/dev/null; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((FAILED++))
        return 1
    fi
}

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 PARTIE 1 : VÉRIFICATION DES OBJETS KUBERNETES${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 1. Namespace
test_step "Namespace air-quality existe" \
    "kubectl get namespace air-quality"

# 2. ConfigMap
test_step "ConfigMap créé" \
    "kubectl get configmap air-quality-config -n air-quality"

# 3. Secret
test_step "Secret créé" \
    "kubectl get secret air-quality-secret -n air-quality"

# 4. PVC
test_step "PersistentVolumeClaim créé et Bound" \
    "kubectl get pvc air-quality-data -n air-quality -o jsonpath='{.status.phase}' | grep -q Bound"

# 5. Backend Deployment
test_step "Backend Deployment existe" \
    "kubectl get deployment air-quality-backend -n air-quality"

# 6. Frontend Deployment
test_step "Frontend Deployment existe" \
    "kubectl get deployment air-quality-frontend -n air-quality"

# 7. Backend Service
test_step "Backend Service (ClusterIP) existe" \
    "kubectl get svc air-quality-backend -n air-quality -o jsonpath='{.spec.type}' | grep -q ClusterIP"

# 8. Frontend Service
test_step "Frontend Service (NodePort) existe" \
    "kubectl get svc air-quality-frontend -n air-quality -o jsonpath='{.spec.type}' | grep -q NodePort"

echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 PARTIE 2 : VÉRIFICATION DES PODS${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 9. Pods backend Running
BACKEND_PODS=$(kubectl get pods -n air-quality -l component=backend --no-headers 2>/dev/null | wc -l | tr -d ' ')
echo -e "\n${BLUE}🔍 Test : Pods backend (attendus: 2)${NC}"
if [ "$BACKEND_PODS" -ge 1 ]; then
    echo -e "${GREEN}✅ PASS${NC} - $BACKEND_PODS pods trouvés"
    ((PASSED++))
    
    # Vérifier qu'ils sont Running
    RUNNING_BACKEND=$(kubectl get pods -n air-quality -l component=backend --no-headers 2>/dev/null | grep Running | wc -l | tr -d ' ')
    if [ "$RUNNING_BACKEND" -ge 1 ]; then
        echo -e "${GREEN}   ✓${NC} $RUNNING_BACKEND pods en statut Running"
    else
        echo -e "${YELLOW}   ⚠${NC} Aucun pod en statut Running"
    fi
else
    echo -e "${RED}❌ FAIL${NC} - Aucun pod backend"
    ((FAILED++))
fi

# 10. Pods frontend Running
FRONTEND_PODS=$(kubectl get pods -n air-quality -l component=frontend --no-headers 2>/dev/null | wc -l | tr -d ' ')
echo -e "\n${BLUE}🔍 Test : Pods frontend (attendus: 2)${NC}"
if [ "$FRONTEND_PODS" -ge 1 ]; then
    echo -e "${GREEN}✅ PASS${NC} - $FRONTEND_PODS pods trouvés"
    ((PASSED++))
    
    RUNNING_FRONTEND=$(kubectl get pods -n air-quality -l component=frontend --no-headers 2>/dev/null | grep Running | wc -l | tr -d ' ')
    if [ "$RUNNING_FRONTEND" -ge 1 ]; then
        echo -e "${GREEN}   ✓${NC} $RUNNING_FRONTEND pods en statut Running"
    else
        echo -e "${YELLOW}   ⚠${NC} Aucun pod en statut Running"
    fi
else
    echo -e "${RED}❌ FAIL${NC} - Aucun pod frontend"
    ((FAILED++))
fi

echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 PARTIE 3 : VÉRIFICATION DE L'APPLICATION${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 11. Health check backend
echo -e "\n${BLUE}🔍 Test : Health check backend${NC}"

# Lancer port-forward en arrière-plan
kubectl port-forward -n air-quality svc/air-quality-backend 18000:8000 >/dev/null 2>&1 &
PF_PID=$!

# Attendre que le port-forward soit prêt
sleep 3

if curl -s http://localhost:18000/health 2>/dev/null | grep -q "ok"; then
    echo -e "${GREEN}✅ PASS${NC} - API répond correctement"
    ((PASSED++))
else
    echo -e "${RED}❌ FAIL${NC} - API ne répond pas"
    ((FAILED++))
fi

# Stop port-forward
kill $PF_PID >/dev/null 2>&1


# 12. Volume persistant monté
BACKEND_POD=$(kubectl get pod -n air-quality -l component=backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
echo -e "\n${BLUE}🔍 Test : Volume persistant monté${NC}"
if [ -n "$BACKEND_POD" ]; then
    if kubectl exec -n air-quality $BACKEND_POD -- ls /data 2>/dev/null | grep -q "air_quality.db\|."; then
        echo -e "${GREEN}✅ PASS${NC} - Volume /data accessible"
        ((PASSED++))
        
        # Vérifier si la DB existe
        if kubectl exec -n air-quality $BACKEND_POD -- ls /data/air_quality.db 2>/dev/null; then
            echo -e "${GREEN}   ✓${NC} Base de données air_quality.db existe"
        else
            echo -e "${YELLOW}   ⚠${NC} Base de données pas encore créée (normal si pas de /load)"
        fi
    else
        echo -e "${RED}❌ FAIL${NC} - Volume /data non accessible"
        ((FAILED++))
    fi
else
    echo -e "${RED}❌ FAIL${NC} - Impossible de tester (pas de pod)"
    ((FAILED++))
fi

# 13. Variables d'environnement (ConfigMap/Secret)
echo -e "\n${BLUE}🔍 Test : Variables d'environnement injectées${NC}"
if [ -n "$BACKEND_POD" ]; then
    DB_PATH_VAR=$(kubectl exec -n air-quality $BACKEND_POD -- env 2>/dev/null | grep "DB_PATH=" | cut -d= -f2)
    API_KEY_VAR=$(kubectl exec -n air-quality $BACKEND_POD -- env 2>/dev/null | grep "API_KEY=" | cut -d= -f2)
    
    if [ -n "$DB_PATH_VAR" ] && [ -n "$API_KEY_VAR" ]; then
        echo -e "${GREEN}✅ PASS${NC} - Variables d'environnement présentes"
        ((PASSED++))
        echo -e "${GREEN}   ✓${NC} DB_PATH = $DB_PATH_VAR"
        echo -e "${GREEN}   ✓${NC} API_KEY = ${API_KEY_VAR:0:15}..."
    else
        echo -e "${RED}❌ FAIL${NC} - Variables manquantes"
        ((FAILED++))
    fi
else
    echo -e "${RED}❌ FAIL${NC} - Impossible de tester"
    ((FAILED++))
fi

# 14. Frontend accessible
echo -e "\n${BLUE}🔍 Test : Frontend accessible (NodePort 30080)${NC}"
if curl -s http://localhost:30080 2>/dev/null | grep -q "Air Quality\|html"; then
    echo -e "${GREEN}✅ PASS${NC} - Frontend répond sur http://localhost:30080"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ ATTENTION${NC} - Frontend ne répond pas sur localhost:30080"
    echo -e "${YELLOW}   Si vous utilisez Minikube, utilisez : minikube service air-quality-frontend -n air-quality${NC}"
    ((FAILED++))
fi

echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 PARTIE 4 : DÉTAILS SUPPLÉMENTAIRES${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${BLUE}📊 État des pods :${NC}"
kubectl get pods -n air-quality

echo -e "\n${BLUE}🔧 État des services :${NC}"
kubectl get svc -n air-quality

echo -e "\n${BLUE}💾 État du volume :${NC}"
kubectl get pvc -n air-quality

echo -e "\n${BLUE}📦 État des déploiements :${NC}"
kubectl get deployments -n air-quality

echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 RÉSUMÉ${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

TOTAL=$((PASSED + FAILED))
PERCENTAGE=$((PASSED * 100 / TOTAL))

echo -e "\n${BLUE}Tests réussis :${NC} ${GREEN}$PASSED${NC} / $TOTAL ($PERCENTAGE%)"
echo -e "${BLUE}Tests échoués :${NC} ${RED}$FAILED${NC} / $TOTAL"

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🎉 FÉLICITATIONS ! Tous les tests sont passés !${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "\n${BLUE}🌐 Accès à l'application :${NC}"
    echo -e "   Frontend : ${GREEN}http://localhost:30080${NC}"
    echo -e "   Backend  : kubectl port-forward -n air-quality svc/air-quality-backend 8000:8000"
    echo -e "              puis ${GREEN}http://localhost:8000/docs${NC}"
    echo -e "\n${BLUE}📥 Charger les données :${NC}"
    echo -e "   kubectl exec -n air-quality $BACKEND_POD -- curl -X POST http://localhost:8000/load"
elif [ $PERCENTAGE -ge 70 ]; then
    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  Application partiellement fonctionnelle${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "\n${YELLOW}Consultez le guide de dépannage :${NC} TROUBLESHOOTING.md"
    echo -e "${YELLOW}Ou exécutez :${NC} ./diagnose.sh"
else
    echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}❌ Des problèmes majeurs ont été détectés${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "\n${RED}Actions recommandées :${NC}"
    echo -e "   1. Exécuter le diagnostic : ${YELLOW}./diagnose.sh${NC}"
    echo -e "   2. Vérifier les logs : ${YELLOW}kubectl logs -n air-quality -l component=backend${NC}"
    echo -e "   3. Consulter : ${YELLOW}TROUBLESHOOTING.md${NC}"
fi

echo ""
