from flask import Flask, render_template, request, redirect, url_for
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///vps_monitor.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# VPS 信息模型
class VPS(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    ip_address = db.Column(db.String(100), nullable=False)
    uptime_days = db.Column(db.Integer, nullable=False)
    traffic = db.Column(db.String(100), nullable=False)
    virtualization = db.Column(db.String(100), nullable=False)
    packet_loss = db.Column(db.Float, nullable=False)

# 创建数据库
with app.app_context():
    db.create_all()

# 路由：主页
@app.route('/')
def index():
    vps_list = VPS.query.all()
    return render_template('index.html', vps_list=vps_list)

# 路由：添加 VPS
@app.route('/add_vps', methods=['GET', 'POST'])
def add_vps():
    if request.method == 'POST':
        name = request.form['name']
        ip_address = request.form['ip_address']
        uptime_days = request.form['uptime_days']
        traffic = request.form['traffic']
        virtualization = request.form['virtualization']
        packet_loss = request.form['packet_loss']

        new_vps = VPS(
            name=name,
            ip_address=ip_address,
            uptime_days=uptime_days,
            traffic=traffic,
            virtualization=virtualization,
            packet_loss=packet_loss
        )
        db.session.add(new_vps)
        db.session.commit()
        return redirect(url_for('index'))
    return render_template('add_vps.html')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8080)
