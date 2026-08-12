#!/bin/bash
if [[ -n "${__COLOR_LOADED:-}" ]]; then
    return
fi
export __COLOR_LOADED=1

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 通用输出函数
info() {
    echo -e "${GREEN}[INFO] $* ${NC}"
}
warn() {
    echo -e "${YELLOW}[WARN] $* ${NC}"
}
error() {
    echo -e "${RED}[ERROR] $* ${NC}"
}

# 全局运维常量，以后新增配置全部写这里
WORK_DIR="/opt/app"
LOG_DIR="/var/log/ops"