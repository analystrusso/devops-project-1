# devops-project-1

A locally hosted Apache web server running in Kubernetes (minikube), monitored with Prometheus and Grafana, with automated content updates via GitHub Actions using a self-hosted runner.

---

## Architecture

```
GitHub repo (website/)
        ↓  push event
GitHub Actions (.github/workflows/website-updater.yml)
        ↓  runs on
Self-hosted runner (Linux Mint host)
        ↓  kubectl commands
Minikube cluster (default namespace)
        ├── Apache pod (httpd:latest + apache-exporter sidecar)
        ├── ConfigMap (apache-cm0) ← serves website/ contents
        └── Prometheus/Grafana (monitoring namespace)
```

When you push changes to `website/`, the runner regenerates the ConfigMap from the current files and restarts the Apache deployment automatically. Initial infrastructure setup is handled by `bootstrap.sh`.

---

## Dependencies

### Host machine
- Linux Mint (or any Debian-based Linux)
- [Docker](https://docs.docker.com/engine/install/)
- [minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [Helm](https://helm.sh/docs/intro/install/)

### Kubernetes
- minikube v1.30+
- kube-prometheus-stack (installed via Helm) — provides Prometheus, Grafana, and the ServiceMonitor CRD

### GitHub
- A GitHub repository with Actions enabled
- A self-hosted runner registered to the repo
- A `KUBECONFIG` repository secret (see Setup below)

---

## Prerequisites

1. Docker is installed and running on the host.
2. minikube is installed on the host.
3. kubectl is installed and on the host's PATH.
4. Helm is installed on the host.
5. You have admin access to the GitHub repository (to register a runner and add secrets).

---

## Setup

### 1. Start minikube

```bash
minikube start
```

### 2. Install Prometheus and Grafana

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace
```

Wait for the Prometheus pods to be ready before continuing:

```bash
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=prometheus \
  -n monitoring --timeout=120s
```

### 3. Run bootstrap.sh

This generates the ConfigMap from the current contents of `website/` and applies all manifests. Run it once per fresh cluster — you do not need to run it again unless you destroy and recreate the cluster with `minikube delete`.

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

`bootstrap.sh` does the following:
```bash
#!/bin/bash
kubectl create configmap apache-cm0 \
  --from-file=website/ \
  --namespace=default \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f apache-deployment.yaml
kubectl apply -f apache-metrics.yaml
```

> **Why bootstrap.sh?** The ConfigMap is generated dynamically from `website/` at setup time. There is no committed `apache-configmap.yaml` in this repo by design — committing a generated file creates drift. The GitHub Actions workflow handles all updates after initial setup.

### 4. Register the self-hosted runner

Go to: GitHub repo → Settings → Actions → Runners → New self-hosted runner

Select Linux/x64 and follow the generated instructions to download and configure the runner on your Linux Mint host.

Then install it as a service so it persists across reboots:

```bash
sudo ./svc.sh install
sudo ./svc.sh start
```

### 5. Add the KUBECONFIG secret

Generate a base64-encoded kubeconfig from your current minikube context:

```bash
cat ~/.kube/config | base64 -w 0
```

Go to: GitHub repo → Settings → Secrets and variables → Actions → New repository secret

Name: `KUBECONFIG`
Value: the base64 string from the command above.

> **Note:** minikube's kubeconfig points to `192.168.49.2:8443` by default, which is only reachable from the Linux Mint host — exactly where the runner is running. This is intentional.

---

## Workflow

Once setup is complete, the pipeline is fully automated:

1. Edit any file under `website/` and push to `main`.
2. GitHub Actions triggers `.github/workflows/website-updater.yml` on the self-hosted runner.
3. The runner regenerates `apache-cm0` from the current `website/` contents.
4. The runner applies the updated ConfigMap and restarts the Apache deployment.
5. The site reflects the new content within ~2 minutes (bounded by the rollout timeout).

---

## Accessing Services

### Apache (website)
```bash
minikube service apache
```

### Prometheus
```bash
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090
```
Then open `http://localhost:9090`

### Grafana
```bash
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
```
Then open `http://localhost:3000` (default credentials: `admin` / `prom-operator`)

---

## After a Reboot

minikube persists cluster state across reboots. You do not need to re-run `bootstrap.sh`. You do need to restart minikube:

```bash
minikube start
```

If you installed the runner as a service (`svc.sh install`), it starts automatically. If not:

```bash
cd <runner-directory>
./run.sh
```

Only run `bootstrap.sh` again if you have destroyed the cluster with `minikube delete`.

---

## Repository Structure

```
devops-project-1/
├── .github/
│   └── workflows/
│       └── website-updater.yml   # GitHub Actions workflow
├── website/
│   └── index.html                # Web content (changes here trigger the pipeline)
├── apache-deployment.yaml        # Kubernetes Deployment (Apache + exporter sidecar)
├── apache-metrics.yaml           # Service, ServiceMonitor, RBAC for Prometheus
├── bootstrap.sh                  # One-time cluster setup script
└── README.md
```

---

## Known Limitations

- minikube is a single-node local cluster, not suitable for production.
- The self-hosted runner must be on the same host as minikube to reach the API server at `192.168.49.2:8443`.
- Grafana and Prometheus are exposed via port-forward only — no Ingress is configured.
