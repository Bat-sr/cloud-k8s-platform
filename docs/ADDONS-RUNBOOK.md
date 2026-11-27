# Add-ons runbook (Ingress, autoscaling, monitoring, ArgoCD)

Step-by-step commands for the two cluster rounds. Both rounds were run on the AWS lab; the commands below are the ones that worked.
Ports 13000 and 18443 are used for port-forward because Windows reserves some low ports (3000 failed on one machine).

Always start with `.\scripts\lab-up.ps1 -Deploy` and finish with `.\scripts\lab-down.ps1`.

## One-time installs on Windows

```powershell
winget install -e --id Helm.Helm
winget install -e --id GrafanaLabs.k6
```

Open a new PowerShell window afterwards so `helm` and `k6` are found.

## Round 1 — Ingress and autoscaling

`lab-up.ps1 -Deploy` already applied `k8s/aws/` (app, Service, Ingress, HPA).

```powershell
kubectl get ingressclass                 # expect: traefik
kubectl get ingress                      # the Ingress should exist
kubectl -n kube-system get pods,svc | Select-String traefik   # how Traefik is exposed
kubectl top nodes                        # metrics-server works if this prints numbers
kubectl get hpa                          # TARGETS should show a % (not <unknown>)
```

Open `http://<master_public_ip>/` in the browser. If it does not answer, Traefik may not be bound
to port 80 on the nodes — check the `svc` output above and fix before load testing (the security group
allows 80 and 443 from your IP only).

Load test, in two windows:

```powershell
# window 1
kubectl get hpa -w
# window 2
k6 run -e BASE_URL=http://<master_public_ip> loadtest/k6-load.js
```

Take screenshots: HPA going from 2 to more replicas, and the k6 summary. Save them in `docs/images/`.

## Round 2 — Prometheus, Grafana, ArgoCD

Check memory first: `kubectl top nodes`. If a node is above ~70% before you start, do the stages one at a time.

### Prometheus + Grafana

```powershell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
# type your own Grafana password in place of CHANGE-ME; do not commit it
helm install monitoring prometheus-community/kube-prometheus-stack `
  --namespace monitoring --create-namespace `
  -f k8s/monitoring/kube-prometheus-stack-values.yaml `
  --set grafana.adminPassword=CHANGE-ME
kubectl -n monitoring get pods -w
kubectl -n monitoring port-forward service/monitoring-grafana 13000:80
```

Browse to http://localhost:13000, user `admin`. Open the dashboard "Kubernetes / Compute Resources / Namespace (Pods)".

### ArgoCD

```powershell
kubectl create namespace argocd
kubectl apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd get pods -w
# initial admin password (read it, do not paste it anywhere public)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_)) }
kubectl -n argocd port-forward service/argocd-server 18443:443
```

Browse to https://localhost:18443 (accept the self-signed certificate warning), user `admin`.

Then register the app:

```powershell
kubectl apply -f k8s/argocd/application.yaml
# optional lab tweak: show the Ingress as Healthy (it has no LoadBalancer address)
kubectl patch configmap argocd-cm -n argocd --type merge --patch-file k8s/argocd/ingress-health-patch.yaml
```

Test GitOps: change `replicas` or an env value in `k8s/aws/deployment.yaml` on GitHub and watch ArgoCD sync it.
Because the app already exists from `lab-up -Deploy`, ArgoCD simply adopts it.

## Finish

```powershell
.\scripts\lab-down.ps1
```

It destroys the lab and runs the leftover check. Exit code 0 means nothing is left.
