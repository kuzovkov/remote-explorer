#### Remote explorer

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
