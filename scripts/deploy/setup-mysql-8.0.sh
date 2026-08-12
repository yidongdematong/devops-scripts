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
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
else
    echo -e "${RED}配置文件不存在: $CONFIG_FILE${NC}"
    echo -e "${YELLOW}请复制 config/mysql/mysql.env.example 并修改${NC}"
    exit 1
fi

# ====================== 配置检查 ======================
: "${MYSQL_USER:?未设置}"
: "${MYSQL_PASSWORD:?未设置}"
: "${MYSQL_ROOT_PASSWORD:?未设置}"

# ====================== 函数：安全执行 MySQL 命令 ======================
mysql_exec() {
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "$1" 2>/dev/null || {
        echo -e "${RED}MySQL 命令执行失败: $1${NC}"
        return 1
    }
}

# ====================== 主流程 ======================
echo -e "\n${YELLOW}===== 更新系统软件源 =====${NC}"
apt update -y && apt upgrade -y

echo -e "\n${YELLOW}===== 安装 MySQL 8.0 =====${NC}"
apt install mysql-server -y

echo -e "\n${YELLOW}===== 启动并设置开机自启 =====${NC}"
systemctl start mysql
systemctl enable mysql

echo -e "\n${YELLOW}===== 等待 MySQL 服务就绪 =====${NC}"
sleep 3

echo -e "\n${YELLOW}===== 初始化 root 密码 =====${NC}"
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';" 2>/dev/null || {
    echo -e "${YELLOW}⚠️ root 密码可能已设置，跳过${NC}"
}

echo -e "\n${YELLOW}===== 创建用户 $MYSQL_USER 并授权远程访问 =====${NC}"
mysql_exec "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';"
mysql_exec "GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@'%' WITH GRANT OPTION;"
mysql_exec "FLUSH PRIVILEGES;"

echo -e "\n${YELLOW}===== 配置 MySQL 允许远程连接 =====${NC}"
MYSQL_CONFIG="/etc/mysql/mysql.conf.d/mysqld.cnf"
if grep -q "^bind-address" "$MYSQL_CONFIG"; then
    sed -i 's/^bind-address.*$/bind-address = 0.0.0.0/' "$MYSQL_CONFIG"
else
    echo "bind-address = 0.0.0.0" >> "$MYSQL_CONFIG"
fi

echo -e "\n${YELLOW}===== 复制自定义 my.cnf（如存在） =====${NC}"
CUSTOM_CNF="$PROJECT_ROOT/config/mysql/my.cnf"
if [ -f "$CUSTOM_CNF" ]; then
    cp "$CUSTOM_CNF" /etc/mysql/mysql.conf.d/99-custom.cnf
    echo -e "${GREEN}✅ 已复制自定义配置${NC}"
else
    echo -e "${YELLOW}⚠️ 未找到自定义 my.cnf，跳过${NC}"
fi

echo -e "\n${YELLOW}===== 重启 MySQL 使配置生效 =====${NC}"
systemctl restart mysql

echo -e "\n${YELLOW}===== 验证 MySQL 连接 =====${NC}"
if mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h127.0.0.1 -e "SELECT 1" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ $MYSQL_USER 远程登录验证成功${NC}"
else
    echo -e "${RED}❌ $MYSQL_USER 远程登录验证失败，请检查${NC}"
fi

echo -e "\n${YELLOW}===== 开放防火墙 3306 端口 =====${NC}"
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
    ufw allow 3306/tcp
    ufw reload
    echo -e "${GREEN}✅ ufw 已放行 3306${NC}"
else
    echo -e "${YELLOW}⚠️ ufw 未启用，请手动在云安全组/防火墙开放 3306 端口${NC}"
fi

echo -e "\n${BLUE}===== 安装完成 =====${NC}"
echo -e "${GREEN}== 非root用户：$MYSQL_USER${NC}"
echo -e "${GREEN}== 密码：$MYSQL_PASSWORD${NC}"
echo -e "${GREEN}== 已开启远程访问（端口 3306）${NC}"
echo -e "${BLUE}=========================================${NC}"