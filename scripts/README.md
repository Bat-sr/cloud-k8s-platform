# Scripts

Small PowerShell helpers for the AWS lab. They use the AWS CLI and the credentials from `aws login`
(no keys are stored in this repo).

| Script | What it does |
|---|---|
| `check-aws-leftovers.ps1` | Read-only. Lists EC2 instances, EBS volumes, Elastic IPs, NAT gateways and load balancers that still exist in a region, so nothing keeps billing after `terraform destroy`. Exit code 0 = clean, 1 = something left, 2 = check failed. |
| `lab-up.ps1` | Builds the lab: checks your public IP against `allowed_cidr`, `terraform init/plan/apply`, waits for RKE2, downloads the kubeconfig to `~/.kube/rke2-lab.yaml`, waits for all nodes to be Ready, and with `-Deploy` applies `k8s/aws/`. **Uses AWS credits.** |
| `lab-down.ps1` | Destroys the lab, deletes the local kubeconfig and runs `check-aws-leftovers.ps1`. Leaves the S3 state bucket alone. |

Usage:

```
aws login
.\scripts\check-aws-leftovers.ps1                 # default region ap-southeast-1
.\scripts\check-aws-leftovers.ps1 -Region us-east-1
```

Build and tear down the whole lab:

```
aws login
.\scripts\lab-up.ps1 -Deploy
# ... work ...
.\scripts\lab-down.ps1
```

`lab-up.ps1` and `lab-down.ps1` have not been run against AWS yet.
