# Runs Terraform with your current `aws login` session.
# Terraform's AWS provider cannot read `aws login` credentials directly, so this copies
# short-lived credentials into this process only, then runs terraform in the chosen folder.
#
# Usage (from the repo root):
#   .\terraform\tf.ps1 bootstrap init
#   .\terraform\tf.ps1 bootstrap apply
#   .\terraform\tf.ps1 lab init '-backend-config=backend.hcl'
#   .\terraform\tf.ps1 lab plan -out=tfplan
#   .\terraform\tf.ps1 lab apply tfplan
#   .\terraform\tf.ps1 lab destroy
#
# Targets:  bootstrap = terraform/bootstrap/state-bucket   lab = terraform/envs/aws-lab

$ErrorActionPreference = "Stop"

$targets = @{
    bootstrap = "bootstrap/state-bucket"
    lab       = "envs/aws-lab"
}

if ($args.Count -lt 2 -or -not $targets.ContainsKey([string]$args[0])) {
    Write-Error "Usage: .\terraform\tf.ps1 <bootstrap|lab> <terraform arguments>   e.g. .\terraform\tf.ps1 lab plan -out=tfplan"
}

$dir  = Join-Path $PSScriptRoot $targets[[string]$args[0]]
$rest = $args[1..($args.Count - 1)]

# Old AWS_* variables from an earlier run would be preferred by the CLI and are probably expired
Remove-Item Env:AWS_ACCESS_KEY_ID, Env:AWS_SECRET_ACCESS_KEY, Env:AWS_SESSION_TOKEN -ErrorAction SilentlyContinue

$json = aws configure export-credentials --format process
if ($LASTEXITCODE -ne 0 -or -not $json) {
    Write-Error "No AWS session found. Run 'aws login' first."
}
$creds = $json | ConvertFrom-Json

$env:AWS_ACCESS_KEY_ID     = $creds.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $creds.SecretAccessKey
$env:AWS_SESSION_TOKEN     = $creds.SessionToken

terraform "-chdir=$dir" @rest
exit $LASTEXITCODE
