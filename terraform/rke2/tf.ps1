# Runs Terraform with your current `aws login` session.
# Terraform's AWS provider cannot read `aws login` credentials directly,
# so this copies short-lived credentials into this process only, then runs terraform.
#
# Usage (from terraform/rke2):
#   .\tf.ps1 plan -out=tfplan
#   .\tf.ps1 apply tfplan
#   .\tf.ps1 destroy

$ErrorActionPreference = "Stop"

$creds = aws configure export-credentials --format process | ConvertFrom-Json
if (-not $creds.AccessKeyId) {
    Write-Error "No AWS session found. Run 'aws login' first."
}

$env:AWS_ACCESS_KEY_ID     = $creds.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $creds.SecretAccessKey
$env:AWS_SESSION_TOKEN     = $creds.SessionToken

terraform @args
exit $LASTEXITCODE
