#!/bin/bash
set -e

echo "正在安装依赖..."
apt update && apt install -y nginx python3 python3-pip unzip git net-tools

echo "安装并配置 Prometheus..."
useradd -m -s /bin/bash prometheus || true
mkdir -p /opt/prometheus && cd /opt/prometheus
curl -LO https://github.com/prometheus/prometheus/releases/download/v2.47.0/prometheus-2.47.0.linux-amd64.tar.gz
tar -xzf prometheus-2.47.0.linux-amd64.tar.gz --strip-components=1
rm prometheus-2.47.0.linux-amd64.tar.gz
cat <<EOF > /opt/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'vps_monitor'
    static_configs:
      - targets: ['localhost:9000']
EOF

chown -R prometheus:prometheus /opt/prometheus
cat <<EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
After=network.target

[Service]
User=prometheus
ExecStart=/opt/prometheus/prometheus --config.file=/opt/prometheus/prometheus.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now prometheus

echo "安装并配置 Grafana..."
apt install -y software-properties-common
apt-add-repository "deb https://packages.grafana.com/oss/deb stable main" && apt update
apt install -y grafana
systemctl enable --now grafana-server

echo "安装并配置 Flask 应用..."
mkdir -p /opt/vps_monitor && cd /opt/vps_monitor
cat <<EOF > app.py
from flask import Flask, jsonify
from prometheus_client import Gauge, start_http_server
import time, os

app = Flask(__name__)

# Metrics
uptime = Gauge('vps_uptime_days', 'Uptime in days')
cpu_load = Gauge('vps_cpu_load', 'CPU Load Average')
packet_loss = Gauge('vps_packet_loss', 'Packet Loss Rate')
traffic = Gauge('vps_traffic', 'Network Traffic in GB')

# Dummy Data
@app.route('/metrics')
def metrics():
    uptime.set(1234)  # Example: Replace with actual uptime
    cpu_load.set(0.5)  # Example: Replace with actual load
    packet_loss.set(0.01)  # Example: Replace with actual packet loss
    traffic.set(300)  # Example: Replace with actual traffic in GB
    return jsonify({
        "uptime_days": 1234,
        "cpu_load": 0.5,
        "packet_loss_rate": 0.01,
        "traffic_gb": 300
    })

if __name__ == '__main__':
    start_http_server(9000)  # Prometheus endpoint
    app.run(host='0.0.0.0', port=80)
EOF

pip3 install flask prometheus_client
cat <<EOF > /etc/systemd/system/vps_monitor.service
[Unit]
Description=VPS Monitor
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/vps_monitor/app.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now vps_monitor

echo "配置 Nginx..."
cat <<EOF > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF
systemctl reload nginx

echo "所有服务已安装并启动！"
echo "访问地址：http://<你的服务器IP>"
