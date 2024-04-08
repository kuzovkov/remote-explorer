#### Remote explorer
It's dockerized application from https://github.com/kalcaddle/kodbox

##### Install
```bash
git clone https://github.com/kuzovkov/remote-explorer
cd remote-explorer 
docker-compose build
```
Edit volume mappping in `docker-compose yml` as yuo need 
```bash
docker-compose up -d
sudo chmod 777 -R app/web
```

Go to `http://localhost:8043`

Interface looks like this:

![desktop inteface](screen1.png?raw=true)


![file explorer](screen2.png?raw=true)



##### Proxing with Nginx
```conf                                                                           /etc/nginx/sites-available/downloads                                                                                      
server {
        listen          80;
        listen         443 ssl http2;
        server_name downloads.kuzovkov12.ru;


        allow 77.40.56.139;
        deny all;
        #SSL
        if ($scheme = http) {
            return 301 https://$server_name$request_uri;
        }


        location / {
                proxy_pass http://localhost:8043/;
                proxy_set_header Host $http_host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-Proto http;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_http_version 1.1;
                proxy_read_timeout 86400;
                client_max_body_size 0;
                proxy_redirect off;
                proxy_buffering off;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";

        }


        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        ssl_certificate /etc/nginx/ssl/downloads.kuzovkov12.ru/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/downloads.kuzovkov12.ru/privkey.pem;

        #include /etc/nginx/ssl-params.conf; #optional
        access_log /var/log/downloads-nginx-access.log;
        error_log /var/log/downloads-nginx-error.log;
}

```
