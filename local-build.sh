#!/bin/bash
#
# 本地 Docker 构建入口
# 用法: ./local-build.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

# 检查 Docker
if ! command -v docker &>/dev/null; then
    echo "错误: Docker 未安装"
    exit 1
fi

if ! docker info &>/dev/null; then
    echo "错误: Docker 未运行"
    exit 1
fi

mkdir -p output

echo "========================================="
echo " openEuler RISC-V Rootfs Docker 构建"
echo "========================================="

echo "步骤 1/2: 构建 Docker 镜像..."
docker build -t rootfs-builder:latest .

echo ""
echo "步骤 2/2: 在容器内构建 rootfs..."
docker run --rm --privileged \
    -v "$(pwd)/output:/output" \
    -v /dev:/dev \
    -v /dev/pts:/dev/pts \
    -v /sys:/sys \
    -v /proc:/proc \
    rootfs-builder:latest \
    bash /workspace/build-rootfs.sh

echo ""
echo "========================================="
echo " 构建完成！"
echo "========================================="
echo "输出目录: $(pwd)/output"

if [ -d "output" ] && [ "$(ls -A output)" ]; then
    echo ""
    echo "生成的文件:"
    ls -lh output/
    echo ""
    du -sh --apparent-size output/*.zst output/*.tar.gz 2>/dev/null || true
else
    echo "警告: 没有找到输出文件"
fi

echo "========================================="
