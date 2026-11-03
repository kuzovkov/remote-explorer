---
name: remote-explorer-docker
description: Use when building, running, debugging, or modifying the Docker Compose setup, Dockerfile, or container networking for Remote Explorer.
metadata:
  category: devops
  triggers: docker, docker-compose, rebuild, container, fpm-socket, build-args
---

# Remote Explorer Docker Operations

Use this skill when managing the Docker lifecycle, containers, networks, and build configurations for Remote Explorer.

## Architecture & Service Map

The stack comprises two interdependent services defined in `docker-compose.yml`:

| Service | Image / Build | Role | Mounts / Volumes |
|---|---|---|---|
| `app` | Context `./app`, Dockerfile `Dockerfile` | PHP 8.2 FPM with Kodbox | `./app/web:/var/www/html`<br>`share:/run/php`<br>Host download folder |
| `nginx` | `nginx:1.18-alpine` | Web server & reverse proxy | `./nginx/conf.d:/etc/nginx/conf.d:ro`<br>`./nginx/nginx.conf:/etc/nginx/nginx.conf:ro`<br>`share:/run/php`<br>`./app/web:/var/www/html` |

Both containers share the `live` bridge network (subnet `168.192.80.2/28`) and a named volume `share` containing the PHP-FPM Unix domain socket (`/run/php/php8.2-fpm.sock`).

## Common Commands

### 1. Build and Start
```bash
# Build the application image (matches host user UID/GID)
docker compose build

# Start services in detached mode
docker compose up -d

# Restart all services
docker compose restart

# View running container status
docker compose ps
```

### 2. Inspecting Logs
```bash
# Stream all logs
docker compose logs -f --tail=100

# Stream logs specifically for app or nginx
docker compose logs -f --tail=100 app
docker compose logs -f --tail=100 nginx
```

### 3. Shell Access inside Containers
```bash
# Enter app container as regular user
docker compose exec app bash

# Enter app container as root (useful for package install or debugging)
docker compose exec -u 0 app bash

# Enter nginx container (Alpine sh)
docker compose exec nginx sh
```

### 4. Cleaning Up
```bash
# Stop containers without removing volumes
docker compose down

# Stop containers and remove volumes (Warning: resets shared socket volume)
docker compose down -v
```

## Dockerfile Compilation Details

The `app/Dockerfile` compiles PHP 8.2 from source along with `imagick`:
- Build arguments:
  - `user`: Host username (default `ubuntu` or `$USER`)
  - `user_id`: Host UID (default `1000` or `$USER_ID`)
  - `group_id`: Host GID (default `1001` or `$GROUP_ID`)
- Built-in extensions compiled:
  `gd` (with freetype, jpeg, webp), `imagick`, `pdo_mysql`, `pdo_pgsql`, `pgsql`, `mysqli`, `imap` (with ssl & kerberos), `intl`, `mbstring`, `soap`, `opcache`, `bcmath`, `exif`, `ftp`, `pcntl`, `sockets`, `zip`, `sodium`.
- Node.js 22.x is also installed in the image along with `composer`.

> [!WARNING]
> Because PHP 8.2 and imagick are compiled from source with `make -j$(nproc)`, rebuilding the Docker image takes several minutes. Only trigger a full rebuild (`docker compose build --no-cache` or `docker compose build`) when modifying `app/Dockerfile` or core dependencies.

## Troubleshooting

### Unix Socket Missing / 502 Bad Gateway
1. Verify `app` container is running: `docker compose ps`.
2. Check socket filename match:
   - Check what FPM creates: `docker compose exec app ls -la /run/php/`
   - Compare with `nginx/conf.d/default.conf` (`fastcgi_pass unix:/run/php/php8.2-fpm-0.sock;`) and `app/conf/www.conf` (`listen = /run/php/php8.2-fpm-0.sock`).
   - If they differ (e.g. `php8.2-fpm.sock` vs `php8.2-fpm-0.sock`), update `nginx/conf.d/default.conf` and reload Nginx (`docker compose exec nginx nginx -s reload`).
3. Check `app` container FPM logs:
   ```bash
   docker compose exec app cat /var/log/php8.2-fpm.log
   ```
4. If permissions on `/run/php` are incorrect:
   ```bash
   docker compose exec -u 0 app chown -R www-data:www-data /run/php
   ```

### Subnet Conflicts
If the configured subnet conflicts with existing Docker networks or local LAN:
- Run `./show-networks.sh` to see existing subnets.
- Update `networks.live.ipam.config[0].subnet` in `docker-compose.yml`.

## Web Endpoint Testing (MANDATORY RULE)

> [!CAUTION]
> **DO NOT USE `curl`** in the terminal to test HTTP endpoints or web access.
> **ALWAYS USE `chrome-devtools` MCP server tools** (`navigate_page`, `take_snapshot`, `list_pages`, `click`, etc.) to verify web application health and UI responses.

