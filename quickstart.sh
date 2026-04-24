#!/bin/bash
#
# 快速开始指南 - openEuler RISC-V Rootfs 构建
#

cat << 'EOF'

╔════════════════════════════════════════════════════════════════════╗
║         openEuler RISC-V Rootfs 构建快速开始                      ║
╚════════════════════════════════════════════════════════════════════╝

📋 前提条件
─────────────────────────────────────────────────────────────────────
✓ Docker 已安装并运行
✓ 足够的磁盘空间 (> 5GB)
✓ 稳定的网络连接

🚀 快速构建（本地）
─────────────────────────────────────────────────────────────────────
推荐使用 Docker（隔离环境）:
$ ./local-build.sh

或直接运行（需要 root 权限）:
$ sudo ./native-build.sh

📦 构建产物
─────────────────────────────────────────────────────────────────────
output/openeuler-rootfs.img.zst  (img.zst 镜像，zst 压缩)
output/openeuler-rootfs.tar.gz   (tar.gz 压缩包)

🐏 QEMU 测试
─────────────────────────────────────────────────────────────────────
⚠️  本 rootfs 不包含内核，需要单独准备

获取内核的方式：
1. 从 openEuler 仓库下载
2. 从已安装系统提取
3. 编译上游 Linux 内核

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
README.md  - 项目说明
BUILD.md   - 详细构建文档

🤝 GitHub Actions
─────────────────────────────────────────────────────────────────────
推送到 main/master 分支自动构建
或手动触发: Actions → Build openEuler RISC-V Rootfs → Run workflow

EOF

if [ -f "build-rootfs.sh" ]; then
    echo ""
    echo "✅ 构建脚本已就绪"
    echo ""
    echo "🔧 自定义配置: 编辑 build-rootfs.sh"
    echo ""
    echo "   OPENEULER_RELEASE=\"24.03\""
    echo "   OPENEULER_VERSION=\"SP2\""
    echo "   ARCH=\"riscv64\""
    echo ""
fi

echo "═════════════════════════════════════════════════════════════════════"