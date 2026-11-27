# Troubleshooting log

Problems I hit, the cause, and the fix.

## `kind` or other tools "is not recognized" right after installing with winget
- **Cause:** the open terminal still has the old PATH.
- **Fix:** close and reopen PowerShell (or refresh PATH) and run the command again.

## `kubectl apply -f k8s/local/` says the path does not exist; `.\tf.ps1` is not recognized
- **Cause:** the terminal was in the wrong folder. Relative paths only work from the repo root, and `.\tf.ps1` only from `terraform\rke2`.
- **Fix:** `cd` into the right folder first, then run the command.

## Terraform fails with `ExpiredToken` even after `aws login` again
- **Cause:** `aws login` gives short-lived credentials. My wrapper exported them as `AWS_*` environment variables, and those stale variables stayed in the PowerShell window. The AWS CLI prefers the variables over the new login, so Terraform kept receiving the expired token.
- **Fix:** remove the variables (`Remove-Item Env:AWS_ACCESS_KEY_ID, Env:AWS_SECRET_ACCESS_KEY, Env:AWS_SESSION_TOKEN`), run `aws login`, check with `aws sts get-caller-identity`, then rerun Terraform. Opening a new terminal also works.

## `ssh` to the master hangs when I run it from the master itself
- **Cause:** I was already logged in to the master and tried to SSH to its own public IP. The firewall only allows my laptop's IP, so the connection timed out.
- **Fix:** press Ctrl+C, run the command directly on the master (or `exit` first and run it from the laptop). The prompt tells which machine I am on (`ubuntu@ip-...` is the server).

## Google Cloud: billing required, no free-trial credit
- **Cause:** the billing account was a paid account with no credits, and the free trial needed a prepayment.
- **Fix:** I did not apply anything there (it would charge my card) and moved the lab back to AWS. The GCP Terraform is kept in `terraform/gcp-rke2/` as a plan-only variant.

## The web page at `localhost:8080` was the wrong app after `kubectl port-forward`
- **Cause:** a local `docker compose up` container was already using port 8080, so the page I opened came from my laptop, not from the cluster. The clue was `Served by` showing a Docker container ID (`f80f2b993a81`) and an uptime of over an hour, instead of a pod name like `cloud-k8s-app-5fd9dc577d-c4bst`.
- **Fix:** forward to another local port (`kubectl port-forward service/cloud-k8s-app 8081:80`) and open `http://localhost:8081`. Always check the `Served by` value to see which app answered.
