<#
.SYNOPSIS
  Destroys the AWS lab, removes the local kubeconfig and checks that nothing is left that costs money.

.DESCRIPTION
  Runs terraform destroy for terraform\envs\aws-lab (asks you to type 'yes' unless -AutoApprove),
  deletes ~/.kube/rke2-lab.yaml, then runs scripts\check-aws-leftovers.ps1.
  The S3 state bucket from terraform\bootstrap is NOT touched.

  Exit code: 0 = destroyed and nothing left, 1 = destroy failed or something is left.

.EXAMPLE
  .\scripts\lab-down.ps1
#>
param(
    [switch]$AutoApprove,
    [string]$Region = "ap-southeast-1"
)

$ErrorActionPreference = "Stop"

$repo     = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$tf       = Join-Path $repo "terraform\tf.ps1"
$kubeFile = Join-Path $HOME ".kube\rke2-lab.yaml"

function Write-Step($message) { Write-Host "`n==> $message" -ForegroundColor Cyan }

Remove-Item Env:AWS_ACCESS_KEY_ID, Env:AWS_SECRET_ACCESS_KEY, Env:AWS_SESSION_TOKEN -ErrorAction SilentlyContinue
aws sts get-caller-identity --query Account --output text | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "ERROR: No valid AWS session. Run 'aws login' first." -ForegroundColor Red; exit 1 }

Write-Step "terraform destroy"
$tfArgs = @("lab", "destroy")
if ($AutoApprove) { $tfArgs += "-auto-approve" }
& $tf @tfArgs
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: terraform destroy failed (exit code $LASTEXITCODE). The lab may still be running." -ForegroundColor Red
    exit 1
}

Write-Step "Removing the local kubeconfig"
if (Test-Path $kubeFile) { Remove-Item $kubeFile -Force }
if ($env:KUBECONFIG -eq $kubeFile) { $env:KUBECONFIG = $null }

Write-Step "Checking for leftovers in $Region"
& (Join-Path $PSScriptRoot "check-aws-leftovers.ps1") -Region $Region
exit $LASTEXITCODE
