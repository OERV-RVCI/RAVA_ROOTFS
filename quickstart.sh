#!/bin/bash
#
# 快速开始指南 - Rootfs 构建
#

cat << 'EOF'

╔════════════════════════════════════════════════════════════════════╗
║              Rootfs 构建快速开始                                  ║
╚════════════════════════════════════════════════════════════════════╝

📋 支持的发行版
─────────────────────────────────────────────────────────────────────
  openeuler  - openEuler 24.03 SP2 RISC-V (RVA20)
  openruyi   - openRuyi RISC-V64

📋 前提条件
─────────────────────────────────────────────────────────────────────
✓ Docker 已安装并运行（推荐）
✓ 足够的磁盘空间 (> 5GB)
✓ 稳定的网络连接

🚀 快速构建
─────────────────────────────────────────────────────────────────────
Docker 方式（推荐）:
  $ ./local-build.sh              # openEuler (默认)
  $ ./local-build.sh openruyi     # openRuyi

本地直接构建（需要 root）:
  $ sudo bash build-rootfs.sh openeuler
  $ sudo bash build-rootfs.sh openruyi

📦 构建产物
─────────────────────────────────────────────────────────────────────
output/{distro}-rootfs.img.zst  (zstd 压缩的 ext4 镜像)
output/{distro}-rootfs.tar.gz   (tar.gz 压缩包)

🐏 QEMU 测试
─────────────────────────────────────────────────────────────────────
⚠️  本 rootfs 不包含内核，需要单独准备

# 先解压镜像
$ zstd -d output/openeuler-rootfs.img.zst -o output/openeuler-rootfs.img

# 准备内核后运行
$ qemu-system-riscv64 \
    -M virt -m 2G -smp 4 \
    -kernel <kernel> \
    -initrd <initrd> \
    -device virtio-blk-device,drive=rootfs \
    -drive if=none,file=output/openeuler-rootfs.img,id=rootfs \
    -append "root=/dev/vda ro console=ttyS0" \
    -nographic

🔐 默认登录
─────────────────────────────────────────────────────────────────────
用户: root
密码: openEuler12#$ (⚠️  登录后请修改!)
分区: 单一 root 分区 (/dev/vda)

📚 更多文档
─────────────────────────────────────────────────────────────────────
README.md  - 完整说明文档

EOF

echo "═════════════════════════════════════════════════════════════════════"
