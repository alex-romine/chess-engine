# run 'sudo -i' first
# don't forget to export SERVER_IP

apt update
apt install python3-pip python3-dev libpq-dev nginx python3-virtualenv -y
-H pip3 install --upgrade pip

make venv
make install
. env/bin/activate


echo '[Unit]
Description=uvicorn socket

[Socket]
ListenStream=/run/uvicorn.sock

[Install]
WantedBy=sockets.target' > /etc/systemd/system/uvicorn.socket

echo '[Unit]
Description=uvicorn daemon
Requires=uvicorn.socket
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/home/ubuntu/chess-engine
ExecStart=/home/ubuntu/chess-engine/env/bin/uvicorn \
          --access-logfile - \
          --workers 5 \
          --bind unix:/run/uvicorn.sock \
          --worker-class uvicorn.workers.UvicornWorker \
          app.main:app

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/uvicorn.service

systemctl start uvicorn.socket

systemctl enable uvicorn.socket


echo "server {
    listen 80;
    server_name ${SERVER_IP};
    location / {
        proxy_pass http://unix:/run/uvicorn.sock;
    }
}" > /etc/nginx/sites-enabled/api

nginx -t


systemctl daemon-reload
systemctl restart uvicorn
systemctl restart nginx
