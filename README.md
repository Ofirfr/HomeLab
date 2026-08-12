# HomeLab
All of my homelab essentials

## Secrets

Secrets are never committed. Every stack that needs one ships a `.env.example`
next to its compose file — copy it to `.env` and fill in the real values:

```sh
cp arr/.env.example arr/.env
$EDITOR arr/.env
```

Stacks and the `.env` each one expects:

| Stack            | `.env` location      | Variables                      |
| ---------------- | -------------------- | ------------------------------ |
| `arr/`           | `arr/.env`           | `SPEED_TEST_KEY`, paths, PUID/PGID |
| `tailscale/`     | `tailscale/.env`     | `TS_AUTHKEY`                   |
| `nginx/`         | `nginx/.env`         | `TS_AUTHKEY`, `PIHOLE_PASSWORD` |
| `nginx/scripts/` | `nginx/scripts/.env` | `TS_AUTHKEY`, `PIHOLE_PASSWORD` |
| `jellyplist/`    | `jellyplist/.env`    | `POSTGRES_USER`, `POSTGRES_PASSWORD`, `IMAGE`, `MUSIC_STORAGE_BASE_PATH` |

The compose files declare these as required, so `docker compose up` fails with
a clear message rather than silently starting with a placeholder value.

Where to generate each one:

- Tailscale auth key — https://login.tailscale.com/admin/settings/keys
- Pi-hole password — `openssl rand -base64 24`
- speedtest-tracker `SPEED_TEST_KEY` — `echo "base64:$(openssl rand -base64 32)"`
