# Scripts

Small PowerShell helpers for the AWS lab. They use the AWS CLI and the credentials from `aws login`
(no keys are stored in this repo).

| Script | What it does |
|---|---|
| `check-aws-leftovers.ps1` | Read-only. Lists EC2 instances, EBS volumes, Elastic IPs, NAT gateways and load balancers that still exist in a region, so nothing keeps billing after `terraform destroy`. Exit code 0 = clean, 1 = something left, 2 = check failed. |

Usage:

```
aws login
.\scripts\check-aws-leftovers.ps1                 # default region ap-southeast-1
.\scripts\check-aws-leftovers.ps1 -Region us-east-1
```
