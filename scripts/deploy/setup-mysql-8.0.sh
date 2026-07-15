#!/bin/bash
# ===========================================
# setup-mysql-8.0.sh
# 功能：安装并配置 MySQL 8.0
# 用法：sudo bash setup-mysql-8.0.sh
# 作者：bobby <yidongdematong@163.com>
# ===========================================

set -e
set -u

# ====================== 颜色变量 ======================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ====================== 加载配置 ======================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/config/mysql/mysql.env"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo -e "${RED} 配置文件不存在: $CONFIG_FILE${NC}"
    echo -e "${YELLOW}请复制 config/mysql.env.example 并修改${NC}"
    exit 1
fi

# ====================== 配置检查 ======================
: "${MYSQL_USER:?未设置}"
: "${MYSQL_PASSWORD:?未设置}"
: "${MYSQL_ROOT_PASSWORD:?未设置}"

# ====================== 主流程 ======================
echo -e "\n${YELLOW}===== 更新系统软件源 =====${NC}"
apt update -y && apt upgrade -y

echo -e "\n${YELLOW}===== 安装 MySQL 8.0 =====${NC}"
apt install mysql-server -y

echo -e "\n${YELLOW}===== 启动并设置开机自启 =====${NC}"
systemctl start mysql
systemctl enable mysql

echo -e "\n${YELLOW}===== 配置 MySQL 允许远程连接 =====${NC}"
sed -i 's/^bind-address.*$/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

echo -e "\n${YELLOW}===== 初始化 root 密码 =====${NC}"
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';"

echo -e "\n${YELLOW}===== 创建用户 $MYSQL_USER 并授权远程访问 =====${NC}"
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
"

echo -e "\n${YELLOW}===== 重启 MySQL 使配置生效 =====${NC}"
systemctl restart mysql

echo -e "\n${YELLOW}===== 开放防火墙 3306 端口 =====${NC}"
ufw allow 3306/tcp
ufw reload

echo -e "\n${BLUE}===== 安装完成 =====${NC}"
echo -e "${GREEN}== 非root用户：$MYSQL_USER${NC}"
echo -e "${GREEN}== 密码：$MYSQL_PASSWORD${NC}"
echo -e "${GREEN}== 已开启远程访问（端口 3306）${NC}"
echo -e "${BLUE}=========================================${NC}"