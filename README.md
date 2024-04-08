#### Remote explorer




##### Get SSl certificates
rename nginx/prod/conf.d/default-ssl.conf -> nginx/prod/conf.d/default-ssl.conf.bak

```bash
mv nginx/conf.d/default-ssl.conf nginx/dev/conf.d/default-ssl.conf.bak
mv nginx/conf.d/default.conf.bak nginx/dev/conf.d/default.conf
docker-compose restart nginx

./certbot.sh <domain-name>

mv nginx/conf.d/default-ssl.conf.bak nginx/dev/conf.d/default-ssl.conf 
mv nginx/conf.d/default.conf nginx/dev/conf.d/default.conf.bak
 
docker-compose restart nginx
```
