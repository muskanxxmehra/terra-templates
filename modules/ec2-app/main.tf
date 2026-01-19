################################################################################
# EC2 App Module - Application Server
# Installs Flask application via user_data
################################################################################

resource "aws_instance" "app" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.key_name
  iam_instance_profile        = var.iam_instance_profile
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  user_data = <<-EOF
    #!/bin/bash
    exec > /var/log/user-data.log 2>&1
    set -x

    echo "=== Starting App Server Setup ==="

    # Update system
    yum update -y

    # Install Python 3 and dependencies
    yum install -y python3 python3-pip python3-devel gcc mysql-devel

    # Install Flask and MySQL connector
    pip3 install flask mysql-connector-python gunicorn

    # Create application directory
    mkdir -p /opt/flask-app

    # Create Flask application
    cat > /opt/flask-app/app.py <<'FLASKAPP'
#!/usr/bin/env python3
"""
Flask Application - Connected to MariaDB
Displays Users and Orders from database
"""
from flask import Flask, jsonify, render_template_string
import mysql.connector
import os

app = Flask(__name__)

# Database configuration
DB_CONFIG = {
    'host': os.environ.get('DB_HOST', '${var.db_host}'),
    'database': os.environ.get('DB_NAME', '${var.db_name}'),
    'user': os.environ.get('DB_USER', '${var.db_user}'),
    'password': os.environ.get('DB_PASSWORD', '${var.db_password}'),
    'port': int(os.environ.get('DB_PORT', '3306'))
}

HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Flask App - AWS + MariaDB</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 900px; margin: 0 auto; }
        h1 { color: #333; border-bottom: 2px solid #007bff; padding-bottom: 10px; }
        h2 { color: #555; margin-top: 30px; }
        .status { padding: 15px; border-radius: 5px; margin: 20px 0; }
        .success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; background: white; }
        th, td { padding: 12px; text-align: left; border: 1px solid #ddd; }
        th { background: #007bff; color: white; }
        tr:nth-child(even) { background: #f9f9f9; }
        .info { background: #e7f3ff; padding: 15px; border-radius: 5px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Flask Application on AWS</h1>
        
        <div class="info">
            <strong>Database Connection:</strong> {{ db_host }}:3306/{{ db_name }}
        </div>
        
        {% if error %}
        <div class="status error">
            <strong>Error:</strong> {{ error }}
        </div>
        {% else %}
        <div class="status success">
            <strong>✓ Connected to MariaDB successfully!</strong>
        </div>
        {% endif %}

        <h2>👥 Users ({{ users|length }} records)</h2>
        {% if users %}
        <table>
            <tr><th>ID</th><th>Name</th><th>Email</th><th>Created</th></tr>
            {% for user in users %}
            <tr>
                <td>{{ user[0] }}</td>
                <td>{{ user[1] }}</td>
                <td>{{ user[2] }}</td>
                <td>{{ user[3] }}</td>
            </tr>
            {% endfor %}
        </table>
        {% else %}
        <p>No users found.</p>
        {% endif %}

        <h2>📦 Orders ({{ orders|length }} records)</h2>
        {% if orders %}
        <table>
            <tr><th>Order ID</th><th>User ID</th><th>Product</th><th>Amount</th><th>Date</th></tr>
            {% for order in orders %}
            <tr>
                <td>{{ order[0] }}</td>
                <td>{{ order[1] }}</td>
                <td>{{ order[2] }}</td>
                <td>${{ "%.2f"|format(order[3]) }}</td>
                <td>{{ order[4] }}</td>
            </tr>
            {% endfor %}
        </table>
        {% else %}
        <p>No orders found.</p>
        {% endif %}
    </div>
</body>
</html>
"""

def get_db_connection():
    return mysql.connector.connect(**DB_CONFIG)

@app.route('/')
def index():
    users = []
    orders = []
    error = None
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("SELECT * FROM users ORDER BY user_id")
        users = cursor.fetchall()
        
        cursor.execute("SELECT * FROM orders ORDER BY order_id")
        orders = cursor.fetchall()
        
        cursor.close()
        conn.close()
    except Exception as e:
        error = str(e)
    
    return render_template_string(
        HTML_TEMPLATE,
        users=users,
        orders=orders,
        error=error,
        db_host=DB_CONFIG['host'],
        db_name=DB_CONFIG['database']
    )

@app.route('/api/users')
def api_users():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM users")
        users = cursor.fetchall()
        cursor.close()
        conn.close()
        return jsonify(users)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/orders')
def api_orders():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM orders")
        orders = cursor.fetchall()
        cursor.close()
        conn.close()
        return jsonify(orders)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health')
def health():
    try:
        conn = get_db_connection()
        conn.close()
        return jsonify({'status': 'healthy', 'database': 'connected'})
    except Exception as e:
        return jsonify({'status': 'unhealthy', 'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=${var.app_port}, debug=True)
FLASKAPP

    # Create systemd service
    cat > /etc/systemd/system/flask-app.service <<'SYSTEMD'
[Unit]
Description=Flask Application
After=network.target

[Service]
User=root
WorkingDirectory=/opt/flask-app
Environment="DB_HOST=${var.db_host}"
Environment="DB_NAME=${var.db_name}"
Environment="DB_USER=${var.db_user}"
Environment="DB_PASSWORD=${var.db_password}"
ExecStart=/usr/local/bin/gunicorn -w 2 -b 0.0.0.0:${var.app_port} app:app
Restart=always

[Install]
WantedBy=multi-user.target
SYSTEMD

    # Reload systemd and start service
    systemctl daemon-reload
    systemctl enable flask-app
    systemctl start flask-app

    echo "=== App Server Setup Complete ==="
  EOF

  tags = merge(var.tags, {
    Name = "${var.environment}-${var.app_name}"
    Role = "Application"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "app" {
  count    = var.create_eip ? 1 : 0
  instance = aws_instance.app.id
  domain   = "vpc"

  tags = merge(var.tags, {
    Name = "${var.environment}-${var.app_name}-eip"
  })
}

