---
name: nginx-proxy-ssl
description: Use when setting up reverse proxying, SSL certificates with Certbot/Let's Encrypt, domain configuration, or external Nginx routing for Remote Explorer.
metadata:
  category: networking
  triggers: nginx, ssl, certbot, reverse-proxy, letsencrypt, domain, websocket
---

# Nginx Reverse Proxy & SSL Configuration

Use this skill when exposing Remote Explorer to the public internet, securing it with SSL/TLS, managing domain certificates with Certbot, or configuring external reverse proxies.

## Reverse Proxy Architecture

```
Internet (HTTPS 443 / HTTP 80)
           │
           ▼
[Host External Nginx / Cloudflare / Traefik]
           │
           │ proxy_pass http://localhost:8043
           ▼
[Internal Docker Nginx (port 8043)]
           │
           │ unix:/run/php/php8.2-fpm.sock
           ▼
[App Container (PHP-FPM Kodbox)]
```

## Recommended Host Nginx Configuration

Save this file under `/etc/nginx/sites-available/remote-explorer` on your host system:

```nginx
server {
    listen 80;
    listen 443 ssl http2;
    server_name files.yourdomain.com;

    # SSL Certificates
    ssl_certificate /etc/letsencrypt/live/files.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/files.yourdomain.com/privkey.pem;

    # HTTP to HTTPS redirect
    if ($scheme = http) {
        return 301 https://$server_name$request_uri;
    }

    # Optional IP Restriction (uncomment to whitelist specific IP)
    # allow 1.2.3.4;
    # deny all;

    location / {
        proxy_pass http://127.0.0.1:8043/;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        
        # HTTP 1.1 & WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Large file upload & streaming optimizations
        client_max_body_size 0;
        proxy_buffering off;
        proxy_redirect off;
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }

    # Certbot ACME challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    access_log /var/log/nginx/remote-explorer-access.log;
    error_log  /var/log/nginx/remote-explorer-error.log;
}
```

## SSL Automation with `certbot.sh`

The repository includes `certbot.sh` for automated issuance:

### 1. Usage
```bash
# Ensure docker-compose is running or configured
chmod +x certbot.sh

# Run for a specific domain:
./certbot.sh files.yourdomain.com
```

### 2. How `certbot.sh` works:
1. Validates `docker-compose` presence.
2. Downloads standard TLS security configs (`options-ssl-nginx.conf`, `ssl-dhparams.pem`) to `./docker/certbot/conf/`.
3. Issues a temporary self-signed certificate so Nginx can boot.
4. Spins up Nginx to serve ACME challenge on port 80.
5. Deletes the dummy certificate and requests genuine Let's Encrypt certs via webroot `/var/www/certbot`.
6. Reloads Nginx with the verified certificates.

## Key Directives Explained

| Directive | Purpose in Remote Explorer |
|---|---|
| `client_max_body_size 0;` | Prevents Nginx from rejecting multi-gigabyte uploads (Kodbox supports chunked and direct large file uploads). |
| `proxy_buffering off;` | Disables buffering so real-time upload/download progress and video streaming stream directly to the browser. |
| `proxy_read_timeout 86400;` | Prevents 504 Gateway Timeout on very long file transfers or backup downloads. |
| `Upgrade` & `Connection` headers | Enables WebSocket support for instant desktop notifications and real-time collaboration. |
