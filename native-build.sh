#!/bin/bash
#
# 直接在本地构建 rootfs（不使用 Docker）
# 需要安装: dnf, qemu-img, e2fsprogs
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

echo "========================================="
echo "openEuler RISC-V Rootfs 本地直接构建"
echo "========================================="

# 检查必要工具
for cmd in dnf qemu-img mkfs.ext4; do
    if ! command -v $cmd &> /dev/null; then
        echo "错误: 缺少必要工具: $cmd"
        echo "请安装: sudo dnf install -y dnf qemu-img e2fsprogs"
        exit 1
    fi
done

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
    echo "警告: 需要 root 权限来创建设备文件"
    echo "请使用: sudo $0"
    exit 1
fi

# 创建输出目录
mkdir -p output

echo "步骤 1: 开始构建..."
sudo bash build-rootfs.sh

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
    du -sh --apparent-size output/*.zst output/*.tar.gz 2>/dev/null || true
else
    echo "警告: 没有找到输出文件"
fi

echo "========================================="