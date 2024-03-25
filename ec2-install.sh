# git clone https://github.com/alex-romine/chess-engine.git
# run as sudo (sudo -i), I acknowledge this is not best practice
# cd into chess-engine

apt update
apt install python3.10-venv python3-pip python3-dev libpq-dev nginx python3-virtualenv -y
-H pip3 install --upgrade pip

make venv
make install
. env/bin/activate


TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
export SERVER_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)


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
ExecStart=/home/ubuntu/chess-engine/venv/bin/uvicorn app.main:app
Environment="SF_VERSION=sf_16.1"
Environment="SF_ARCH=ubuntu-x86-64"

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/uvicorn.service

systemctl start uvicorn.socket

systemctl enable uvicorn.socket


echo "server {
    listen 80;
    server_name ${SERVER_IP};
    location / {
        proxy_pass http://localhost:8000;
    }
}" > /etc/nginx/sites-enabled/api

nginx -t


systemctl daemon-reload
systemctl restart uvicorn
systemctl restart nginx
