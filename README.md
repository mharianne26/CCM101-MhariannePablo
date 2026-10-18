# Laboratory 10 — The Enterprise Cloud Architect
## Secure WordPress + MySQL on Ubuntu Server with Docker

**Course:** CCM101 – Cloud Computing  
**Prepared by:** Pablo, Mharianne P. | Parino, Frankie M. | Villafania, Katrina Joy  
**Section:** BSIT 4 K  
**Instructor:** Jenkielyn C. Torres  
**Date:** October 2026

This project deploys a multi-tier WordPress site backed by MySQL using Docker Compose, persistent volumes, UFW firewall rules, and a scheduled backup script.

## Architecture
See [`architecture-diagram.svg`](architecture-diagram.svg). Open it in a browser or import it into draw.io to export as PNG if required.

## Requirements
- Ubuntu Server VM with internet access
- Docker Engine and Docker Compose plugin
- Git and a GitHub account
- Host-to-VM network access

## Quick start
1. Install Docker Engine and the Compose plugin using Docker's official Ubuntu instructions: https://docs.docker.com/engine/install/ubuntu/
2. Copy `.env.example` to `.env` and set strong, unique passwords.
3. Run `chmod +x automation-script.sh`
4. Run `docker compose up -d`
5. Apply firewall rules only after confirming SSH access: `sudo ufw default deny incoming`, `sudo ufw default allow outgoing`, `sudo ufw allow OpenSSH`, `sudo ufw allow 8080/tcp`, then `sudo ufw enable`.
6. Open `http://SERVER_IP:8080` from the host computer.

## Important security notes
- `.env` contains secrets and must never be committed. It is ignored by `.gitignore`.
- This is a lab baseline, not a production-hardened public deployment. Do not expose it directly to the public internet without TLS, patching, secrets management, monitoring, and a reviewed threat model.
- If SSH uses a nonstandard port, allow that port before enabling UFW to avoid locking yourself out.
- The database container is not published to the host; only WordPress port 8080 is exposed.

## Operations
- Start: `docker compose up -d`
- Stop: `docker compose down` (named volumes remain)
- Status: `docker compose ps`
- Logs: `docker compose logs -f`
- Restart: `docker compose restart`
- Backup: `./automation-script.sh`
- Restore notes: see [`operational-manual.md`](operational-manual.md).

## Repository contents
- `docker-compose.yml` — application stack and persistent volumes
- `.env.example` — configuration template (no real secrets)
- `automation-script.sh` — database and WordPress uploads backup
- `operational-manual.md` — deployment, security, operations, backup, and restore guide
- `final-reflection.md` — reflection draft to personalize
- `architecture-diagram.svg` — architecture diagram
