#!/usr/bin/env bash

# SSHポートを変更
sudo sed -i 's/^#Port 22/Port ${ssh_port}/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Cloud SQL Auth Proxy をインストール
curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/${sql_proxy_version}/cloud-sql-proxy.linux.amd64
chmod +x cloud-sql-proxy
sudo mv cloud-sql-proxy /usr/local/bin

# サービスを作成
echo "[Unit]
Description=Cloud SQL Auth Proxy
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/cloud-sql-proxy --address 0.0.0.0 --port ${sql_proxy_port} ${sql_connection_name} --private-ip
Restart=always

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/cloud-sql-proxy.service

# サービスを起動
sudo systemctl enable cloud-sql-proxy.service
sudo systemctl start cloud-sql-proxy.service
