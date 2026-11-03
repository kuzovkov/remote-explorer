# AGENTS.md — Remote Explorer Guidelines & Context

## Project Overview

**Remote Explorer** is a containerized self-hosted cloud desktop and web file management system based on [kodbox](https://github.com/kalcaddle/kodbox). It allows browsing, uploading, downloading, and previewing remote files (such as host downloads, media, documents) through a modern web UI.

### Architecture & Components

```
                +-----------------------------------------+
                |   Host Browser / External Reverse Proxy  |
                +--------------------+--------------------+
                                     | Port 8043 (HTTP)
                                     v
                  +-------------------------------------+
                  |   Service: nginx (nginx:1.18-alpine) |
                  |   Port 80 -> Host 8043              |
                  +------------------+------------------+
                                     | Unix domain socket:
                                     | /run/php/php8.2-fpm.sock
                                     v (shared volume)
                  +-------------------------------------+
                  |   Service: app (PHP 8.2 + Kodbox)   |
                  |   - Custom Ubuntu 22.04 image       |
                  |   - Compiled PHP 8.2 + FPM          |
                  |   - Node.js 22 & Composer           |
                  +------------------+------------------+
                                     | Mounts
                  +------------------+------------------+
                  |  - ./app/web -> /var/www/html       |
                  |  - Host folder -> /home/user1/      |
                  +-------------------------------------+
```

- **`app` container** (`app/Dockerfile`):
  - Ubuntu 22.04 base with PHP 8.2 compiled from source with extensions (`gd` with freetype/webp/jpeg, `imagick`, `pdo_mysql`, `pdo_pgsql`, `imap`, `intl`, `zip`, `mbstring`, `sodium`, etc.).
  - Node.js 22.x and Composer installed.
  - Matches the host's UID/GID using build args (`USER`, `USER_ID`, `GROUP_ID`).
  - PHP-FPM runs and listens on `/run/php/php8.2-fpm.sock`.
- **`nginx` container**:
  - `nginx:1.18-alpine` serves static assets directly and passes PHP requests via unix socket `/run/php/php8.2-fpm.sock` in the `share` volume.
  - Configuration in `nginx/nginx.conf` and `nginx/conf.d/default.conf`.
- **`kodbox` web app** (`app/web/`):
  - PHP application with web desktop, file explorer, user auth, plugins, and previewers.
  - Runtime cache and uploaded data stored in `app/web/data/`.
- **SSL / Production Proxying**:
  - `certbot.sh` provides automated Let's Encrypt certificates using webroot challenge.
  - Recommended upstream Nginx reverse proxy configuration provided in `README.md`.

---

## Repository Structure

```
.
├── AGENTS.md                  # Agent operating guide & project documentation
├── .agents/                   # Custom agent skills and rules
│   └── skills/                # Domain-specific workflow skills
├── docker-compose.yml         # Main Docker Compose service definitions
├── app/
│   ├── Dockerfile             # PHP 8.2 FPM custom build with extensions
│   ├── Dockerfile.old         # Legacy Dockerfile reference
│   ├── conf/                  # PHP configuration
│   │   ├── php.ini            # PHP runtime configuration
│   │   ├── php-fpm.conf       # FPM master configuration
│   │   └── www.conf           # FPM pool configuration
│   └── web/                   # Kodbox application code & runtime data
│       ├── app/               # Kodbox core PHP code
│       ├── config/            # Kodbox settings & database config
│       ├── data/              # Kodbox user data, cache, session, temp files
│       ├── plugins/           # Kodbox extensions and integrations
│       └── static/            # Static JS, CSS, images
├── nginx/
│   ├── nginx.conf             # Global Nginx HTTP server settings
│   └── conf.d/
│       └── default.conf       # Virtual host config (port 80 -> PHP-FPM socket)
├── certbot/                   # Certbot challenge & SSL config mount
├── certbot.sh                 # Let's Encrypt automated issuance script
└── show-networks.sh           # Diagnostic script for Docker IPAM subnets
```

---

## Operating Instructions & Common Workflows

### 1. Building and Starting Services

```bash
# Build the app image (incorporating host UID/GID)
docker compose build

# Start services in background
docker compose up -d

# Verify container status
docker compose ps

# Check logs for both services
docker compose logs -f --tail=100
```

### 2. Permissions on Kodbox Data

Kodbox requires write permissions on `app/web` (specifically `app/web/data` and `app/web/config`):
```bash
# Ensure web server can write configuration and data
sudo chmod 777 -R app/web
```

### 3. Accessing the Web UI

- Open `http://localhost:8043` in the browser.
- Initial setup prompts for admin user creation and database setup (SQLite is used by default if MySQL/PostgreSQL is not configured).

### 4. Mounting Host Storage

In `docker-compose.yml`, volumes mounted under `app` can be explored via Kodbox:
```yaml
volumes:
  - ./app/web:/var/www/html
  - /path/to/host/folder:/home/user1/data
```
In Kodbox, configure storage path in **Admin -> Storage** or navigate through the local filesystem if enabled for admin users.

### 5. Media Conversion for Web Playback

Kodbox streams video natively if encoded in H.264 + AAC (`mp4`). Convert unsupported containers (`wmv`, `mkv`, `avi`) using ffmpeg:
```bash
for i in *.wmv; do
  ffmpeg -i "$i" -c:v libx264 -crf 23 -profile:v high -r 30 -c:a aac -q:a 100 -ar 48000 "${i%.*}.mp4"
done
```

---

## Critical Rules & Conventions for Agents

1. **Docker Builds are Heavy**: The PHP compilation in `app/Dockerfile` compiles PHP 8.2 and `imagick` from source (`make -j$(nproc)`). Avoid unnecessary rebuilds unless editing PHP extensions, build args, or core packages.
2. **Socket Communication**: Communication between Nginx and PHP-FPM uses a shared unix domain socket (`/run/php/php8.2-fpm-0.sock`). Ensure the socket filename specified in `app/conf/www.conf` (`listen = ...`) and `nginx/conf.d/default.conf` (`fastcgi_pass unix:...`) matches identically. Ensure the `share` volume remains mapped in both services in `docker-compose.yml`.
3. **Upload & Timeout Limits**: For large file transfers in Kodbox:
   - `client_max_body_size` in Nginx must be configured accordingly (set to `0` or high value).
   - In `app/conf/php.ini`, verify `upload_max_filesize`, `post_max_size`, `memory_limit`, and `max_execution_time`.
4. **Preserve User ID Mappings**: `USER`, `USER_ID`, and `GROUP_ID` in `docker-compose.yml` prevent files written by Kodbox from becoming unmanageable by the host user.
5. **Web Testing via Chrome DevTools MCP (MANDATORY)**: Never use `curl` to test or verify web endpoints, URLs, or HTTP responses. Always use the `chrome-devtools` MCP tools (`navigate_page`, `take_snapshot`, `list_pages`, etc.) for all web-related diagnostics and testing.
6. **Always check `.agents/skills/`** for specialized workflows before making complex modifications.

