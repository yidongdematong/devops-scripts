#!/bin/bash
# ===========================================
# docker_cleanup_cron.sh
# 功能：定期清理 Docker 日志和资源
# 用法：sudo bash docker_cleanup_cron.sh
# ===========================================

set -e
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 加载颜色和配置
source "$PROJECT_ROOT/lib/color.sh"
source "$PROJECT_ROOT/config/global.env"

# 确保日志目录存在
mkdir -p "$LOG_DIR"


# 记录开始
info "$(date): Starting Docker cleanup..."

# 清理 Docker 日志（用全局常量控制天数）
find /var/lib/docker/containers -name "*-json.log" -mtime +$DOCKER_LOG_RETENTION_DAYS -exec truncate -s 0 {} \;
info "Docker logs cleaned (retention: ${DOCKER_LOG_RETENTION_DAYS} days)"

# 清理 Docker 资源
docker system prune -f
docker volume prune -f

info "Docker resources pruned"

# 记录完成
info "$(date): Docker cleanup completed."