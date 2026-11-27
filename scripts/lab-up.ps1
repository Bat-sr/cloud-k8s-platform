<#
.SYNOPSIS
  Builds the AWS lab in one go: terraform apply, fetch kubeconfig, wait for the nodes, optionally deploy the app.

.DESCRIPTION
  Steps: check prerequisites and your public IP -> terraform init/plan -> ask for confirmation -> apply
  -> wait until the master has RKE2 -> download kubeconfig to ~/.kube/rke2-lab.yaml
  -> wait until all nodes are Ready -> (with -Deploy) kubectl apply -f k8s/aws.

  This starts using AWS credits. Run scripts\lab-down.ps1 when you are done.
  KUBECONFIG is set for the current PowerShell window only.

.PARAMETER ExpectedNodes
  How many Ready nodes to wait for (master + workers). Default 3.

.PARAMETER Deploy
  Also deploy the manifests in k8s/aws and wait for the rollout.

.PARAMETER AutoApprove
  Skip the "type yes" question before apply.

.PARAMETER SkipIpCheck
  Do not compare allowed_cidr in terraform.tfvars with your current public IP.

.EXAMPLE
  .\scripts\lab-up.ps1 -Deploy
#>
param(
    [int]$ExpectedNodes = 3,
    [int]$TimeoutMinutes = 15,
    [switch]$Deploy,
    [switch]$AutoApprove,
    [switch]$SkipIpCheck
)

$ErrorActionPreference = "Stop"

$repo     = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$tf       = Join-Path $repo "terraform\tf.ps1"
$envDir   = Join-Path $repo "terraform\envs\aws-lab"
$kubeFile = Join-Path $HOME ".kube\rke2-lab.yaml"

function Write-Step($message) { Write-Host "`n==> $message" -ForegroundColor Cyan }
function Stop-WithError($message) { Write-Host "ERROR: $message" -ForegroundColor Red; exit 1 }

function Invoke-Tf {
    param([string[]]$TfArgs)
    & $tf @TfArgs
    if ($LASTEXITCODE -ne 0) { Stop-WithError "terraform $($TfArgs -join ' ') failed (exit code $LASTEXITCODE)." }
}

# --- 1. prerequisites -------------------------------------------------------
Write-Step "Checking prerequisites"
foreach ($cmd in @("aws", "terraform", "kubectl", "ssh", "scp")) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { Stop-WithError "'$cmd' was not found in PATH." }
}
foreach ($file in @("terraform.tfvars", "backend.hcl")) {
    if (-not (Test-Path (Join-Path $envDir $file))) {
        Stop-WithError "Missing terraform\envs\aws-lab\$file (copy the .example file and fill it in; see the README)."
    }
}

# Old AWS_* variables from an earlier run are probably expired and would be preferred by the CLI
Remove-Item Env:AWS_ACCESS_KEY_ID, Env:AWS_SECRET_ACCESS_KEY, Env:AWS_SESSION_TOKEN -ErrorAction SilentlyContinue
aws sts get-caller-identity --query Account --output text | Out-Null
if ($LASTEXITCODE -ne 0) { Stop-WithError "No valid AWS session. Run 'aws login' first." }

if (-not $SkipIpCheck) {
    $myIp  = ([string](Invoke-RestMethod -Uri "https://checkip.amazonaws.com" -TimeoutSec 15)).Trim()
    $match = Select-String -Path (Join-Path $envDir "terraform.tfvars") -Pattern '^\s*allowed_cidr\s*=\s*"([^"]+)"' | Select-Object -First 1
    if ($match) {
        $allowed = $match.Matches[0].Groups[1].Value
        if ($allowed -ne "$myIp/32") {
            Stop-WithError "allowed_cidr is $allowed but your public IP is $myIp. Update terraform.tfvars (or use -SkipIpCheck), otherwise SSH and kubectl will be blocked."
        }
    }
}

# --- 2. terraform -----------------------------------------------------------
Write-Step "terraform init"
Invoke-Tf @("lab", "init", "-input=false", "-backend-config=backend.hcl")

Write-Step "terraform plan"
Invoke-Tf @("lab", "plan", "-input=false", "-out=tfplan")

if (-not $AutoApprove) {
    Write-Host "`nThe next step creates real EC2 instances and starts using AWS credits." -ForegroundColor Yellow
    $answer = Read-Host "Type 'yes' to apply"
    if ($answer -ne "yes") { Write-Host "Cancelled. Nothing was created."; exit 0 }
}

Write-Step "terraform apply"
Invoke-Tf @("lab", "apply", "-input=false", "tfplan")

$masterIp = (& $tf lab output -raw master_public_ip | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or -not $masterIp) { Stop-WithError "Could not read master_public_ip from the Terraform outputs." }
Write-Host "Master public IP: $masterIp"

# --- 3. wait for RKE2 and fetch kubeconfig ----------------------------------
$sshOpts  = @("-o", "StrictHostKeyChecking=accept-new", "-o", "ConnectTimeout=10", "-o", "BatchMode=yes")
$deadline = (Get-Date).AddMinutes($TimeoutMinutes)

Write-Step "Waiting for RKE2 on the master (up to $TimeoutMinutes minutes)"
$ready = $false
$previousPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"   # ssh writes to stderr while the server is still booting
while ((Get-Date) -lt $deadline) {
    ssh @sshOpts "ubuntu@$masterIp" "test -s /etc/rancher/rke2/rke2.yaml" 2>$null
    if ($LASTEXITCODE -eq 0) { $ready = $true; break }
    Write-Host "  not ready yet, trying again in 15 seconds ..."
    Start-Sleep -Seconds 15
}
$ErrorActionPreference = $previousPreference
if (-not $ready) { Stop-WithError "The master did not become ready in $TimeoutMinutes minutes. Check: ssh ubuntu@$masterIp 'sudo tail -50 /var/log/cloud-init-output.log'" }

Write-Step "Downloading kubeconfig to $kubeFile"
New-Item -ItemType Directory -Force (Split-Path $kubeFile) | Out-Null
scp @sshOpts "ubuntu@${masterIp}:/etc/rancher/rke2/rke2.yaml" $kubeFile
if ($LASTEXITCODE -ne 0) { Stop-WithError "scp failed (exit code $LASTEXITCODE)." }
$text = [IO.File]::ReadAllText($kubeFile).Replace("127.0.0.1", $masterIp)
[IO.File]::WriteAllText($kubeFile, $text, (New-Object System.Text.UTF8Encoding($false)))
$env:KUBECONFIG = $kubeFile

# --- 4. wait for the nodes --------------------------------------------------
Write-Step "Waiting for $ExpectedNodes nodes to be Ready"
$deadline = (Get-Date).AddMinutes($TimeoutMinutes)
$allReady = $false
$ErrorActionPreference = "Continue"
while ((Get-Date) -lt $deadline) {
    $lines = kubectl get nodes --no-headers 2>$null
    $readyCount = @($lines | Where-Object { $_ -match '\sReady\s' }).Count
    Write-Host "  $readyCount of $ExpectedNodes nodes Ready"
    if ($readyCount -ge $ExpectedNodes) { $allReady = $true; break }
    Start-Sleep -Seconds 15
}
$ErrorActionPreference = $previousPreference
if (-not $allReady) { Stop-WithError "Not all nodes became Ready in $TimeoutMinutes minutes. Run: kubectl get nodes" }
kubectl get nodes

# --- 5. optional deploy -----------------------------------------------------
if ($Deploy) {
    Write-Step "Deploying k8s/aws"
    kubectl apply -f (Join-Path $repo "k8s\aws")
    if ($LASTEXITCODE -ne 0) { Stop-WithError "kubectl apply failed." }
    kubectl rollout status deployment/cloud-k8s-app --timeout=180s
    if ($LASTEXITCODE -ne 0) { Stop-WithError "The deployment did not finish. Run: kubectl get pods" }
}

Write-Host "`nThe lab is up." -ForegroundColor Green
Write-Host "  SSH to the master : ssh ubuntu@$masterIp"
Write-Host "  kubectl           : works in this window (KUBECONFIG=$kubeFile)"
Write-Host "  Open the app      : kubectl port-forward service/cloud-k8s-app 8081:80   then http://localhost:8081"
Write-Host "  WHEN YOU ARE DONE : .\scripts\lab-down.ps1   (the lab costs credits while it exists)" -ForegroundColor Yellow
