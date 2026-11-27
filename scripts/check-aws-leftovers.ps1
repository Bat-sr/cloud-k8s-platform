<#
.SYNOPSIS
  Lists AWS resources that keep costing money after a lab run (read-only, deletes nothing).

.DESCRIPTION
  Checks one region for EC2 instances that are not terminated, EBS volumes, Elastic IPs,
  NAT gateways and load balancers. Run it after `terraform destroy`.

  Exit code: 0 = nothing left, 1 = something is left, 2 = the check itself failed
  (for example the `aws login` session expired).

.EXAMPLE
  .\scripts\check-aws-leftovers.ps1
  .\scripts\check-aws-leftovers.ps1 -Region us-east-1
#>
param(
    [string]$Region = "ap-southeast-1"
)

$ErrorActionPreference = "Stop"

function Invoke-AwsText {
    param([string[]]$CliArgs)
    $out = & aws @CliArgs --region $Region --output text
    if ($LASTEXITCODE -ne 0) {
        throw "aws $($CliArgs[0..1] -join ' ') failed (exit code $LASTEXITCODE). If the session expired, run 'aws login'."
    }
    return ($out | Out-String).Trim()
}

$checks = @(
    @{ Name = "EC2 instances (pending/running/stopping/stopped)"
       Args = @("ec2", "describe-instances",
                "--filters", "Name=instance-state-name,Values=pending,running,stopping,stopped",
                "--query", "Reservations[].Instances[].[InstanceId,State.Name,InstanceType]") },
    @{ Name = "EBS volumes"
       Args = @("ec2", "describe-volumes",
                "--query", "Volumes[].[VolumeId,Size,State]") },
    @{ Name = "Elastic IP addresses"
       Args = @("ec2", "describe-addresses",
                "--query", "Addresses[].[PublicIp,AllocationId]") },
    @{ Name = "NAT gateways (pending/available)"
       Args = @("ec2", "describe-nat-gateways",
                "--filter", "Name=state,Values=pending,available",
                "--query", "NatGateways[].[NatGatewayId,State]") },
    @{ Name = "Load balancers"
       Args = @("elbv2", "describe-load-balancers",
                "--query", "LoadBalancers[].[LoadBalancerName,Type,State.Code]") }
)

try {
    Write-Host "Checking region $Region ..."
    $found = 0
    foreach ($check in $checks) {
        $text = Invoke-AwsText -CliArgs $check.Args
        if ($text -and $text -ne "None") {
            Write-Host "FOUND  $($check.Name)" -ForegroundColor Yellow
            $text -split "`n" | ForEach-Object { Write-Host "         $_" }
            $found++
        }
        else {
            Write-Host "OK     $($check.Name): none" -ForegroundColor Green
        }
    }

    if ($found -gt 0) {
        Write-Host "`n$found kind(s) of resource still exist. Check the AWS console, or run 'terraform destroy'." -ForegroundColor Yellow
        exit 1
    }
    Write-Host "`nNothing left in $Region." -ForegroundColor Green
    exit 0
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 2
}
