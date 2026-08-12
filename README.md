# HomeLab
All of my homelab essentials

## Secrets

Secrets are never committed. Each stack that needs one ships a `.env.example`
next to its compose file — copy it to `.env` and fill in the real values:

```sh
cp tailscale/.env.example tailscale/.env
$EDITOR tailscale/.env
```

Tailscale auth keys are generated at
https://login.tailscale.com/admin/settings/keys.
