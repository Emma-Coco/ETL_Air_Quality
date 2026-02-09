# Guide Kubernetes - Air Quality ETL

## Prérequis

- Docker Desktop avec Kubernetes activé
- OU Minikube installé
- kubectl configuré

## Déploiement rapide
```bash
# Rendre les scripts exécutables
chmod +x deploy-k8s.sh cleanup-k8s.sh

# Déployer l'application
./deploy-k8s.sh
```

## Vérifications

### Pods
```bash
kubectl get pods -n air-quality
kubectl logs -n air-quality -l component=backend
kubectl logs -n air-quality -l component=frontend
```

### Services
```bash
kubectl get svc -n air-quality
kubectl describe svc air-quality-backend -n air-quality
```

### ConfigMap
```bash
kubectl get configmap -n air-quality
kubectl describe configmap air-quality-config -n air-quality
```

### Secret
```bash
kubectl get secret -n air-quality
kubectl get secret air-quality-secret -n air-quality -o jsonpath='{.data.api-key}' | base64 -d
```

### Volume
```bash
kubectl get pvc -n air-quality
kubectl describe pvc air-quality-data -n air-quality
```

## Accès à l'application

### Docker Desktop
```bash
# Frontend
open http://localhost:30080

# Backend (via port-forward)
kubectl port-forward -n air-quality svc/air-quality-backend 8000:8000
open http://localhost:8000/docs
```

### Minikube
```bash
# Frontend
minikube service air-quality-frontend -n air-quality

# Backend
minikube service air-quality-backend -n air-quality
```

## Tests de résilience

### Supprimer un pod backend
```bash
kubectl delete pod -n air-quality -l component=backend
kubectl get pods -n air-quality -w
```

### Vérifier la persistance des données
```bash
# Lister les données
BACKEND_POD=$(kubectl get pod -n air-quality -l component=backend -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n air-quality $BACKEND_POD -- ls -la /data

# Supprimer tous les pods backend
kubectl delete pod -n air-quality -l component=backend

# Attendre la recréation
kubectl wait --for=condition=ready pod -l component=backend -n air-quality --timeout=60s

# Vérifier que la DB existe toujours
BACKEND_POD=$(kubectl get pod -n air-quality -l component=backend -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n air-quality $BACKEND_POD -- ls -la /data
```

## Scaling
```bash
# Augmenter le nombre de replicas
kubectl scale deployment air-quality-backend -n air-quality --replicas=3
kubectl get pods -n air-quality -w
```

## Debug

### Logs en temps réel
```bash
kubectl logs -n air-quality -l component=backend -f
```

### Shell dans un pod
```bash
kubectl exec -it -n air-quality deployment/air-quality-backend -- /bin/sh
```

### Vérifier la base SQLite
```bash
BACKEND_POD=$(kubectl get pod -n air-quality -l component=backend -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n air-quality $BACKEND_POD -- sqlite3 /data/air_quality.db "SELECT COUNT(*) FROM daily_aggregates;"
```

## Nettoyage
```bash
./cleanup-k8s.sh
# OU
kubectl delete namespace air-quality
```