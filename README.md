# Magoradesk App Builder

Build the Magoradesk P2P cryptocurrency trading Android app and serve it as a
**Tor hidden service** (.onion) — fully automated, single-command VPS setup.

## Quick Start

```bash
# On a fresh Ubuntu 22.04 / 24.04 VPS (as root):
git clone https://github.com/bitbybit91/app-builder.git
cd app-builder
sudo bash setup-vps.sh
```

When the script finishes it prints:

```
  🧅 Hidden service : http://<random>.onion
  📱 Latest APK      : /var/www/apk-panel/builds/magoradesk-debug-….apk
```

Open the `.onion` address in the **Tor Browser** to reach the download panel.

## What Gets Installed

| Component | Version / Notes |
|-----------|-----------------|
| OpenJDK | 17 |
| Android SDK | Platform 34, Build-tools 34.0.0 |
| Gradle | 8.5 (wrapper downloaded at build time) |
| nginx | System package — listens on `127.0.0.1:80` |
| Tor | System package — creates a hidden service on port 80 |

## Repository Layout

```
.
├── setup-vps.sh                  # One-shot VPS provisioning (JDK, SDK, nginx, Tor)
├── setup-tor-hidden-service.sh   # Standalone Tor hidden-service installer
├── build-and-serve.sh            # Rebuild APK + refresh download panel
├── nginx/
│   ├── nginx-hidden-service.conf # nginx server block template
│   └── index.html                # Static download-panel template
├── tor/
│   └── torrc.template            # Tor config reference
└── README.md
```

## Scripts

### `setup-vps.sh`

All-in-one provisioning script. Installs every dependency, builds the debug
APK (when app source is present), configures nginx to listen only on
`127.0.0.1:80`, and starts a Tor hidden service that forwards port 80 to
nginx. Safe to re-run (idempotent).

### `setup-tor-hidden-service.sh`

Lightweight, standalone script that **only** sets up Tor. Useful if you
already have nginx running and just want to add a hidden service:

```bash
sudo bash setup-tor-hidden-service.sh                # default port 80
sudo bash setup-tor-hidden-service.sh --port 443     # custom port
```

### `build-and-serve.sh`

Pulls latest code, rebuilds the APK, copies it to the nginx serve directory,
prunes old builds, and regenerates the HTML download page. Run manually or via
cron:

```bash
sudo bash build-and-serve.sh                 # full rebuild
sudo bash build-and-serve.sh --skip-build    # regenerate HTML only

# Cron — rebuild every 6 hours:
0 */6 * * * /path/to/build-and-serve.sh >> /var/log/build-and-serve.log 2>&1
```

## Hidden Service Details

- nginx binds to `127.0.0.1:80` (not exposed to the public internet).
- Tor maps port 80 of the `.onion` address to `127.0.0.1:80`.
- The `.onion` hostname is stored in `/var/lib/tor/hidden_service/hostname`.
- To retrieve your address at any time:

```bash
sudo cat /var/lib/tor/hidden_service/hostname
```

## Signed Release Builds

To produce a signed release APK alongside the debug build, set
`KEYSTORE_PATH` before running `build-and-serve.sh`:

```bash
export KEYSTORE_PATH=/path/to/your.keystore
export KEYSTORE_PASSWORD=changeme
export KEY_ALIAS=upload
export KEY_PASSWORD=changeme
sudo -E bash build-and-serve.sh
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `gradlew: not found` | Ensure you cloned the repo; the wrapper script is committed. The jar is downloaded at build time. |
| `Tor started but hostname not created` | Check `journalctl -u tor`. Make sure `/var/lib/tor/hidden_service` is owned by `debian-tor` with mode `700`. |
| `nginx -t` fails | Run `nginx -t` to see the specific error. Most likely `__SERVE_DIR__` was not substituted — re-run `setup-vps.sh`. |
| APK not found after build | App source code must be present under `app/`. See the `copilot/add-admin-wallet-percentage` branch for the full app. |
| Build-tools version mismatch | Edit `CMDLINE_TOOLS_VERSION` in `setup-vps.sh` or run `sdkmanager --install "build-tools;VERSION"`. |

## License

This project is provided as-is for educational and personal use.
