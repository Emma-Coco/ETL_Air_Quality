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

test_step "Namespace air-quality existe" "kubectl get namespace air-quality"
test_step "ConfigMap créé" "kubectl get configmap air-quality-config -n air-quality"
test_step "Secret créé" "kubectl get secret air-quality-secret -n air-quality"
test_step "PersistentVolumeClaim créé et Bound" "kubectl get pvc air-quality-data -n air-quality -o jsonpath='{.status.phase}' | grep -q Bound"
test_step "Backend Deployment existe" "kubectl get deployment air-quality-backend -n air-quality"
test_step "Frontend Deployment existe" "kubectl get deployment air-quality-frontend -n air-quality"
test_step "Backend Service existe" "kubectl get svc api -n air-quality"

echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 PARTIE 2 : VÉRIFICATION DES PODS${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Test Pods backend
BACKEND_PODS=$(kubectl get pods -n air-quality -l component=backend --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [ "$BACKEND_PODS" -ge 1 ]; then
    echo -e "${GREEN}✅ PASS${NC} - $BACKEND_PODS pods trouvés"
    ((PASSED++))
else
    echo -e "${RED}❌ FAIL${NC} - Aucun pod backend"
    ((FAILED++))
fi

echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 PARTIE 3 : VÉRIFICATION DE L'APPLICATION${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Health check via port-forward
kubectl port-forward -n air-quality svc/api 18000:8000 >/dev/null 2>&1 &
PF_PID=$!
sleep 3
if curl -s http://localhost:18000/health | grep -q "ok"; then
    echo -e "${GREEN}✅ PASS${NC} - API répond correctement"
    ((PASSED++))
else
    echo -e "${RED}❌ FAIL${NC} - API ne répond pas"
    ((FAILED++))
fi
kill $PF_PID >/dev/null 2>&1

echo -e "\n${BLUE}Tests réussis :${NC} ${GREEN}$PASSED${NC}"
echo -e "${BLUE}Tests échoués :${NC} ${RED}$FAILED${NC}"