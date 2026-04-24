#!/bin/bash
#
# 本地测试构建脚本
# 用于在本地测试 rootfs 构建流程
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

echo "========================================="
echo "openEuler RISC-V Rootfs 本地测试构建"
echo "========================================="

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo "错误: Docker 未安装"
    exit 1
fi

# 检查 Docker 是否运行
if ! docker info &> /dev/null; then
    echo "错误: Docker 未运行"
    exit 1
fi

# 创建输出目录
mkdir -p output

# 构建 Docker 镜像
echo "步骤 1: 构建 Docker 镜像..."
docker build -t rootfs-builder:local .

echo ""
echo "步骤 2: 构建 rootfs..."
docker run --rm --privileged \
    -v "$(pwd)/output:/workspace" \
    rootfs-builder:local

echo ""
echo "========================================="
echo "构建完成！"
echo "========================================="
echo "输出目录: $(pwd)/output"
echo ""

# 显示生成的文件
if [ -d "output" ] && [ "$(ls -A output)" ]; then
    echo "生成的文件:"
    ls -lh output/
    echo ""
    echo "文件大小:"
    du -sh output/*
else
    echo "警告: 没有找到输出文件"
fi

echo "========================================="