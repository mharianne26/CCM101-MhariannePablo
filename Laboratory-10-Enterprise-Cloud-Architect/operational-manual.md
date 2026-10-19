# Operational Manual
## Secure Multi-Tier Web Application — WordPress + MySQL

**Course:** CCM101 – Cloud Computing  
**Prepared by:** Pablo, Mharianne P. | Parino, Frankie M. | Villafania, Katrina Joy  
**Section:** BSIT 4 K  
**Instructor:** Jenkielyn C. Torres  
**Date:** October 2026

---

## 1. Project Overview

This project runs WordPress as the presentation/application tier and MySQL as the database tier on an Ubuntu Server virtual machine. Docker Compose defines the services, networks, and persistent storage. UFW limits inbound traffic, while a Bash script backs up the database and uploaded media on a schedule.

### Objectives
- Deploy a linked, multi-container web application.
- Preserve database and WordPress files across container recreation and VM restarts.
- Apply a default-deny inbound firewall policy.
- Automate backups using Bash and cron.
- Document deployment and maintenance for a future operator.

## 2. Architecture

Host computer and browser → Ubuntu Server VM → UFW firewall → Docker Compose WordPress container (port 8080 on host) → private Docker backend network → MySQL container. MySQL is not published to the host. Docker named volumes persist MySQL data and WordPress files.

See `architecture-diagram.svg`.

## 3. Prerequisites

- Ubuntu Server VM with network access.
- VM network mode that permits the host to reach the VM (bridged networking or a correctly configured NAT port forward).
- SSH access, if managed remotely.
- Docker Engine and Docker Compose plugin.
- Git.

## 4. Install Docker

Follow the official installation guide for Ubuntu: https://docs.docker.com/engine/install/ubuntu/

Verify:
```bash
docker --version
docker compose version
```

If using Docker without `sudo`, add your user to the Docker group only if appropriate for your lab. Membership in the Docker group grants root-equivalent control of the host.

## 5. Configure the Application

1. Place this project folder on the Ubuntu VM.
2. In the project folder, create the private environment file:
   ```bash
   cp .env.example .env
   nano .env
   ```
3. Replace both placeholder passwords with strong, unique values. Do not commit `.env`.
4. Protect the file:
   ```bash
   chmod 600 .env
   ```
5. Validate and deploy:
   ```bash
   docker compose config
   docker compose up -d
   docker compose ps
   ```
6. Find the VM address with `hostname -I`.
7. From the host browser, open `http://SERVER_IP:8080` and complete the WordPress setup.

## 6. Firewall Hardening

**Caution:** Ensure you have console access or allow the actual SSH port before enabling UFW. A wrong firewall rule can disconnect remote administration.

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw allow 8080/tcp
sudo ufw enable
sudo ufw status verbose
```

Only allow port 8080 if the host needs to reach WordPress. If SSH uses a custom port, allow that port instead of relying only on `OpenSSH`. Do not add a MySQL port rule: the database is available only on the private Docker network. Test SSH and browser access after applying rules.

## 7. Persistent Storage

Compose creates named volumes:
- `db_data` stores MySQL data in `/var/lib/mysql`.
- `wordpress_data` stores WordPress files in `/var/www/html`.

`docker compose down` removes containers and networks but normally keeps named volumes. **Never run `docker compose down -v` unless you intend to delete the persistent data.** Volumes are not a substitute for off-VM backups.

## 8. Automated Backup

Make the script executable:
```bash
chmod +x automation-script.sh
```

Run a manual test while the stack is running:
```bash
./automation-script.sh
ls -lh backups/
```

The script creates a compressed MySQL dump and a compressed archive of `wp-content/uploads`. Backups are stored in `backups/`, excluded from Git, and limited to the 14 newest files of each type. Store an additional copy somewhere outside the VM for disaster recovery.

### Schedule with cron

Edit the current user's crontab:
```bash
crontab -e
```

Add a daily 2:00 AM job, replacing `/absolute/path/to/Laboratory-10-Enterprise-Cloud-Architect` with the real absolute directory:
```cron
0 2 * * * /absolute/path/to/Laboratory-10-Enterprise-Cloud-Architect/automation-script.sh >> /absolute/path/to/Laboratory-10-Enterprise-Cloud-Architect/backup-cron.log 2>&1
```

Check the saved schedule with `crontab -l`. The VM must be running for the scheduled job to execute.

## 9. Restore Procedure

1. Stop WordPress to avoid writes during restoration:
   ```bash
   docker compose stop wordpress
   ```
2. Restore the database from a selected SQL dump:
   ```bash
   gunzip -c backups/mysql-YYYYMMDD-HHMMSS.sql.gz | docker compose exec -T db sh -c 'exec mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"'
   ```
3. Restore uploads if needed (from the project directory):
   ```bash
   docker compose exec -T wordpress tar -xzf - -C /var/www/html < backups/wordpress-uploads-YYYYMMDD-HHMMSS.tar.gz
   ```
   If your Docker/Compose setup does not support the archive stream as written, extract the archive into a temporary directory and copy the `wp-content/uploads` directory into the WordPress container.
4. Start WordPress and verify the site:
   ```bash
   docker compose start wordpress
   docker compose logs --tail=100 wordpress
   ```
5. Confirm pages, media, and administrative login work.

Perform a test restore in a separate lab environment before relying on backups.

## 10. Routine Operations and Troubleshooting

| Task | Command |
|---|---|
| View service status | `docker compose ps` |
| Follow logs | `docker compose logs -f` |
| Restart services | `docker compose restart` |
| Stop containers, keep volumes | `docker compose down` |
| Start services | `docker compose up -d` |
| Validate Compose configuration | `docker compose config` |
| Check firewall | `sudo ufw status verbose` |
| View scheduled jobs | `crontab -l` |

If WordPress cannot connect to MySQL, check `docker compose ps`, `docker compose logs db`, `.env` values, and wait for the database health check. If the site is unreachable, verify the VM IP, network mode, UFW rules, and port 8080 mapping.

## 11. Security and Limitations

- Keep `.env` and backup archives private.
- Use unique passwords and restrict access to the VM.
- Update Ubuntu and container images regularly, testing updates before applying them.
- Do not expose MySQL directly to the internet.
- This lab setup does not configure HTTPS, external monitoring, encrypted off-site backups, or centralized secrets management. Add and test these before any public or production deployment.
- Pin reviewed image versions/digests for repeatable deployments; verify supported versions before upgrading.

## 12. Acceptance Checklist

- [ ] Architecture diagram included.
- [ ] Ubuntu Server VM is accessible from the host.
- [ ] Docker Compose starts both services.
- [ ] WordPress setup page loads on port 8080.
- [ ] MySQL data and WordPress files persist after restart.
- [ ] UFW default-deny policy is enabled and required ports are allowed.
- [ ] Backup script runs and produces both archives.
- [ ] Cron job is installed and documented.
- [ ] `.env` and backup files are not committed to GitHub.
- [ ] GitHub repository contains all documentation and source files.

## 13. References

- Docker Engine on Ubuntu: https://docs.docker.com/engine/install/ubuntu/
- Docker Compose: https://docs.docker.com/compose/
- Ubuntu UFW guide: https://help.ubuntu.com/community/UFW
- WordPress Docker image: https://hub.docker.com/_/wordpress
- MySQL Docker image: https://hub.docker.com/_/mysql
