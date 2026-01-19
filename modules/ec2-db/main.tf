################################################################################
# EC2 DB Module - Database Server
# Installs and configures MariaDB via user_data
# Placed in PUBLIC subnet for internet access
################################################################################

resource "aws_instance" "db" {
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

    echo "=== Starting DB Server Setup ==="

    # Update system
    yum update -y

    # Install MariaDB
    amazon-linux-extras install mariadb10.5 -y

    # Start and enable MariaDB
    systemctl start mariadb
    systemctl enable mariadb

    # Wait for MariaDB to be ready
    sleep 10

    # Configure MariaDB
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${var.db_password}';"
    mysql -u root -p'${var.db_password}' -e "CREATE DATABASE IF NOT EXISTS ${var.db_name};"
    mysql -u root -p'${var.db_password}' -e "CREATE USER IF NOT EXISTS '${var.db_user}'@'%' IDENTIFIED BY '${var.db_password}';"
    mysql -u root -p'${var.db_password}' -e "GRANT ALL PRIVILEGES ON ${var.db_name}.* TO '${var.db_user}'@'%';"
    mysql -u root -p'${var.db_password}' -e "FLUSH PRIVILEGES;"

    # Create USERS table
    mysql -u root -p'${var.db_password}' ${var.db_name} -e "
    CREATE TABLE IF NOT EXISTS users (
      user_id INT PRIMARY KEY AUTO_INCREMENT,
      name VARCHAR(100) NOT NULL,
      email VARCHAR(100) UNIQUE NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );"

    # Create ORDERS table
    mysql -u root -p'${var.db_password}' ${var.db_name} -e "
    CREATE TABLE IF NOT EXISTS orders (
      order_id INT PRIMARY KEY AUTO_INCREMENT,
      user_id INT NOT NULL,
      product VARCHAR(200) NOT NULL,
      amount DECIMAL(10,2) NOT NULL,
      order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(user_id)
    );"

    # Seed sample data - USERS
    mysql -u root -p'${var.db_password}' ${var.db_name} -e "
    INSERT IGNORE INTO users (user_id, name, email) VALUES
    (1, 'Alice Johnson', 'alice@example.com'),
    (2, 'Bob Smith', 'bob@example.com'),
    (3, 'Carol Williams', 'carol@example.com'),
    (4, 'David Brown', 'david@example.com'),
    (5, 'Eva Martinez', 'eva@example.com'),
    (6, 'Frank Lee', 'frank@example.com'),
    (7, 'Grace Kim', 'grace@example.com'),
    (8, 'Henry Wilson', 'henry@example.com'),
    (9, 'Iris Chen', 'iris@example.com'),
    (10, 'Jack Taylor', 'jack@example.com');"

    # Seed sample data - ORDERS
    mysql -u root -p'${var.db_password}' ${var.db_name} -e "
    INSERT IGNORE INTO orders (order_id, user_id, product, amount) VALUES
    (1, 1, 'Laptop Pro 15', 1299.99),
    (2, 1, 'Wireless Mouse', 49.99),
    (3, 2, 'Mechanical Keyboard', 159.99),
    (4, 2, 'Monitor 27 inch', 399.99),
    (5, 3, 'USB-C Hub', 79.99),
    (6, 3, 'Webcam HD', 129.99),
    (7, 4, 'Headphones Wireless', 249.99),
    (8, 5, 'SSD 1TB', 109.99),
    (9, 5, 'RAM 32GB Kit', 149.99),
    (10, 6, 'Graphics Card RTX', 599.99),
    (11, 7, 'Power Supply 750W', 89.99),
    (12, 7, 'PC Case ATX', 119.99),
    (13, 8, 'CPU Cooler', 69.99),
    (14, 9, 'Motherboard Gaming', 289.99),
    (15, 10, 'NVMe SSD 2TB', 199.99);"

    # Configure MariaDB to allow remote connections
    cat >> /etc/my.cnf.d/mariadb-server.cnf <<MYCNF
[mysqld]
bind-address=0.0.0.0
MYCNF

    # Restart MariaDB to apply config
    systemctl restart mariadb

    echo "=== DB Server Setup Complete ==="
  EOF

  tags = merge(var.tags, {
    Name = "${var.environment}-db-server"
    Role = "Database"
  })

  lifecycle {
    create_before_destroy = true
  }
}

