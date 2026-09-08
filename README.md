# GCP homelab VPS — Phase 1

This phase creates the infrastructure foundation only:

- a custom VPC and subnet;
- explicit SSH and web firewall rules;
- one regional static external IPv4 address;
- one `e2-standard-2` Debian 12 VM with a disposable 20 GB boot disk;
- one separately managed, protected 30 GB state disk;
- a dedicated, currently unprivileged runtime service account; and
- an idempotent bootstrap that mounts the state disk at `/srv/state`.

It intentionally does **not** clone the private Git repository, read Secret
Manager values, start containers, schedule backups, or create snapshots. Those
belong to later checkpoints.

## Safety properties

- The VM has GCP deletion protection enabled.
- The state disk has OpenTofu `prevent_destroy` enabled.
- The boot disk is disposable and is deleted with the VM.
- The state disk is a distinct resource and is not auto-deleted with the VM.
- The bootstrap formats the state disk only when neither a filesystem nor any
  other recognizable disk signature exists.
- Instance metadata explicitly disables OS Login and supplies only the chosen
  administrator's public key; `sshd` explicitly disables password login.
- No secret value is accepted by this configuration or written to state.
- `terraform.tfvars`, plans, and state are excluded from Git.

The state disk contains these initial directories:

```text
/srv/state/
├── caddy/
│   ├── config/
│   └── data/
├── grafana/
├── headscale/
├── qr-logger/
└── victoriametrics/
```

## 1. Prepare a dedicated SSH key

If the key does not already exist:

```bash
ssh-keygen \
  -t ed25519 \
  -a 64 \
  -f ~/.ssh/gcp-homelab_ed25519 \
  -C "gcp-homelab"
```

Use a passphrase. Only the `.pub` file is read by OpenTofu.

## 2. Create the local variable file

From the `opentofu` directory:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Review `terraform.tfvars`. In particular, change `ssh_source_ranges` to your
public IPv4 address followed by `/32` when practical. The example uses
`0.0.0.0/0` so that dynamic residential addresses do not lock you out, but that
exposes the SSH port to Internet scanning. Authentication remains public-key
only.

## 3. Initialize and inspect — do not apply yet

```bash
mkdir -p state
tofu init
tofu fmt -recursive
tofu validate
tofu plan -out=phase1.tfplan
tofu show -no-color phase1.tfplan | less
```

Commit the generated `.terraform.lock.hcl`; it records the selected provider
package checksums. Do not commit `terraform.tfvars`, the saved plan, or anything
under `state/`.

The first plan should contain approximately eleven creations:

- three required APIs;
- one VPC and one subnet;
- two firewall rules;
- one static IPv4 address;
- one runtime service account;
- one protected state disk; and
- one VM.

There should be no deletion and no secret value in the plan. Stop after reading
the plan and share its resource summary before running `tofu apply`.

## Later operational notes

Because `deletion_protection = true`, a normal destroy of the VM is rejected
until protection is deliberately disabled. Because the state disk uses
`prevent_destroy`, a destroy of the entire stack is also rejected rather than
silently deleting application state.

OpenTofu currently uses local state at `opentofu/state/terraform.tfstate`. It
will become part of the encrypted workstation backup later. A remote backend
inside the same GCP project would be useful for locking, but cannot be the only
copy for a provider-loss disaster.
