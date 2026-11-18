# Cloud-Native Platform on AWS (Terraform + EKS + GitOps)

Work in progress. A small web app deployed to Kubernetes on AWS, built entirely as code.

## Goal
Show an end-to-end cloud workflow: infrastructure as code, containers, Kubernetes,
automated CI/CD, monitoring and autoscaling, with no long-lived AWS access keys.

## Planned architecture
GitHub -> GitHub Actions (build, scan) -> ECR -> ArgoCD -> EKS -> ALB
Terraform builds the VPC, EKS, ECR and IAM. Prometheus/Grafana watch the cluster.

## Repository layout
| Folder | Purpose |
|---|---|
| app/ | Sample web app and Dockerfile |
| terraform/ | AWS infrastructure (VPC, EKS, ECR, IAM) |
| k8s/ | Kubernetes manifests, Helm values, ArgoCD apps |
| .github/workflows/ | CI/CD pipelines |
| docs/ | Diagrams, decisions, troubleshooting log |

## Progress
- [ ] Workspace setup
- [ ] App + local Kubernetes
- [ ] Terraform VPC
- [ ] EKS
- [ ] CI/CD + ArgoCD
- [ ] Monitoring + autoscaling
- [ ] Security, cost, docs

## Cost warning
EKS, NAT gateways and load balancers bill by the hour. Always run terraform destroy when done.

## Quick start (local)
Requires Docker Desktop.

```
docker compose up --build
```
Then open http://localhost:8080 (health check: http://localhost:8080/health).
Stop with Ctrl+C, then `docker compose down`.
