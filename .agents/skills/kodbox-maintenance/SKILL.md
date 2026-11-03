---
name: kodbox-maintenance
description: Use when configuring, updating, backing up, or troubleshooting the Kodbox web application, permissions, storage, plugins, or database.
metadata:
  category: application
  triggers: kodbox, permissions, chmod, data-folder, storage-mount, plugins, database
---

# Kodbox Maintenance & Configuration

Use this skill when managing the Kodbox cloud desktop file manager in Remote Explorer.

## Directory Layout in `app/web/`

```
app/web/
├── app/                  # Kodbox framework & core modules
├── config/               # System configuration & database credentials
│   ├── config.php        # Core system configuration
│   └── setting_user.php  # User-specific runtime settings
├── data/                 # Dynamic runtime data (MUST BE WRITABLE)
│   ├── cache/            # Template & system cache
│   ├── files/            # Uploaded files managed by Kodbox
│   ├── session/          # User session store
│   ├── system/           # SQLite databases (if using SQLite)
│   └── temp/             # Upload chunks and temporary archives
├── plugins/              # Kodbox plugins (previewers, auth, utilities)
├── static/               # Frontend scripts, styles, icons
└── index.php             # Application entry point
```

## Critical Procedures

### 1. Permissions Fix (Host & Container)
Kodbox frequently throws permission warnings during install, updates, or when uploading files if `app/web` is not writable by the web server process:
```bash
# On host machine:
sudo chmod -R 777 app/web

# Or set ownership to match container user/group:
sudo chown -R $USER:$USER app/web
```
If executing inside container:
```bash
docker compose exec -u 0 app chmod -R 777 /var/www/html/data /var/www/html/config
```

### 2. Database Options

Kodbox supports:
- **SQLite** (Default / Zero Config): Stored under `app/web/data/system/`. Good for personal single-user instances.
- **MySQL / MariaDB**: Recommended for multi-user setups or large directory trees.
- **PostgreSQL**: Fully supported (PDO PostgreSQL driver is pre-compiled in `app/Dockerfile`).

To adjust database settings manually:
Check `app/web/config/config.php` or `app/web/config/setting_user.php`.

### 3. Adding New Storage Mounts

To make external or host folders visible inside Kodbox:

1. Add the volume mount to `app` service in `docker-compose.yml`:
   ```yaml
   services:
     app:
       volumes:
         - ./app/web:/var/www/html
         - /path/to/media:/media/storage:ro # or :rw
   ```
2. Restart the container:
   ```bash
   docker compose up -d
   ```
3. Inside Kodbox Web UI:
   - Log in as administrator.
   - Go to **Desktop -> Admin -> Storage Management -> Add Storage**.
   - Select **Local Storage** and set the path to `/media/storage`.

### 4. Adjusting Upload File Sizes

Large file uploads require synchronization between Nginx, PHP, and Kodbox:

1. **PHP Configuration** (`app/conf/php.ini`):
   ```ini
   upload_max_filesize = 10240M
   post_max_size = 10240M
   memory_limit = 1024M
   max_execution_time = 3600
   max_input_time = 3600
   ```
2. **Nginx Configuration** (`nginx/nginx.conf` and `nginx/conf.d/default.conf`):
   ```nginx
   client_max_body_size 0; # Disables client body size checking
   ```
3. Restart containers:
   ```bash
   docker compose restart
   ```

### 5. Clearing Cache

When styles, templates, or plugins fail to update:
```bash
rm -rf app/web/data/cache/*
rm -rf app/web/data/temp/*
```
Or inside container:
```bash
docker compose exec app rm -rf /var/www/html/data/cache/*
```

## Backup & Recovery

To create a complete snapshot of all files, configurations, and Kodbox data:
```bash
# Backup configuration and uploaded data
tar -czf "kodbox_backup_$(date +%Y%m%d).tar.gz" app/web/config app/web/data
```
To restore:
```bash
tar -xzf kodbox_backup_YYYYMMDD.tar.gz
sudo chmod -R 777 app/web/data app/web/config
```
