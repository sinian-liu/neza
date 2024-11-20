import psutil
import platform
import socket
import time
from flask import Flask, render_template

app = Flask(__name__)

def get_system_info():
    # 获取系统信息
    uname_info = platform.uname()
    system_info = {
        "system": uname_info.system,
        "node_name": uname_info.node,
        "release": uname_info.release,
        "version": uname_info.version,
        "machine": uname_info.machine,
        "processor": uname_info.processor,
        "hostname": socket.gethostname(),
        "uptime": get_uptime(),
        "load_avg": psutil.getloadavg(),
        "cpu_percent": psutil.cpu_percent(),
        "memory": psutil.virtual_memory(),
        "disk": psutil.disk_usage('/'),
        "network": psutil.net_io_counters(),
        "packet_loss": get_packet_loss()
    }
    return system_info

def get_uptime():
    # 获取系统启动时间
    uptime_seconds = time.time() - psutil.boot_time()
    return str(time.strftime('%H:%M:%S', time.gmtime(uptime_seconds)))

def get_packet_loss():
    # 获取网络丢包率 (可以做一个简单的网络探测)
    # 这里简化为网络流量数据，真实应用中可能需要更复杂的网络包检测
    net = psutil.net_if_addrs()
    packet_loss = {
        "bytes_sent": net['eth0'][0].address if 'eth0' in net else "未知",
        "bytes_recv": net['eth0'][1].address if 'eth0' in net else "未知"
    }
    return packet_loss

@app.route('/')
def home():
    system_info = get_system_info()
    return render_template('index.html', system_info=system_info)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
