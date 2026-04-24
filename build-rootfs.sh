#!/bin/bash
#
# openEuler RISC-V Rootfs 构建脚本
# 支持两种模式：
# 1. 容器内模式：直接安装到容器根目录（需要清理）
# 2. 宿主机模式：使用 --installroot 到指定目录
#

set -e

# 配置变量
OPENEULER_RELEASE="24.03"
OPENEULER_VERSION="SP2"
ARCH="riscv64"

# 检测运行环境
if [ -f "/.dockerenv" ]; then
    echo "检测到在容器内运行"
    # 在容器内使用 installroot 方式（更干净）
    ROOTFS_DIR="/workspace/rootfs"
    ROOTFS_IMG="/workspace/openeuler-rootfs.img.zst"
    ROOTFS_TARBALL="/workspace/openeuler-rootfs.tar.gz"
    BASE_LIST="/workspace/base.list"
else
    echo "在宿主机运行"
    WORKSPACE="$(pwd)"
    ROOTFS_DIR="${WORKSPACE}/rootfs"
    ROOTFS_IMG="${WORKSPACE}/openeuler-rootfs.img.zst"
    ROOTFS_TARBALL="${WORKSPACE}/openeuler-rootfs.tar.gz"
    BASE_LIST="${WORKSPACE}/base.list"
fi

# 清理旧的构建产物
rm -rf "${ROOTFS_DIR}"
rm -f "${ROOTFS_IMG}"
rm -f "${ROOTFS_TARBALL}"

# 创建 rootfs 根目录
mkdir -p "${ROOTFS_DIR}"

echo "========================================="
echo "openEuler Rootfs 构建"
echo "========================================="
echo "版本: ${OPENEULER_RELEASE} ${OPENEULER_VERSION}"
echo "架构: ${ARCH}"
echo "构建目录: ${ROOTFS_DIR}"
echo "使用容器默认软件源配置"
echo "========================================="

echo "从 base.list 读取包列表并安装..."
if [ -f "${BASE_LIST}" ]; then
    PACKAGES=$(cat "${BASE_LIST}" | tr '\n' ' ')
    echo "安装以下软件包:"
    echo "${PACKAGES}"

    dnf install -y \
        --installroot="${ROOTFS_DIR}" \
        --forcearch="${ARCH}" \
        --nodocs \
        --allowerasing \
        ${PACKAGES}
else
    echo "错误: base.list 文件不存在 (${BASE_LIST})"
    exit 1
fi

echo "软件包安装完成"

# 创建必要的设备文件（dnf 不会创建这些）
echo "创建设备文件..."
mkdir -p "${ROOTFS_DIR}/dev"
mknod -m 600 "${ROOTFS_DIR}/dev/console" c 5 1
mknod -m 666 "${ROOTFS_DIR}/dev/null" c 1 3
mknod -m 666 "${ROOTFS_DIR}/dev/zero" c 1 5
mknod -m 666 "${ROOTFS_DIR}/dev/random" c 1 8
mknod -m 666 "${ROOTFS_DIR}/dev/urandom" c 1 9
ln -sf /proc/self/fd "${ROOTFS_DIR}/dev/fd"
ln -sf /proc/self/fd/0 "${ROOTFS_DIR}/dev/stdin"
ln -sf /proc/self/fd/1 "${ROOTFS_DIR}/dev/stdout"
ln -sf /proc/self/fd/2 "${ROOTFS_DIR}/dev/stderr"
ln -sf /proc/kcore "${ROOTFS_DIR}/dev/core"

# 配置基本系统
echo "配置基本系统..."

# 创建 fstab（单一 root 分区）
cat > "${ROOTFS_DIR}/etc/fstab" << 'EOF'
# /etc/fstab
# Created by rootfs build script
# Single root partition

/dev/vda  /      ext4    defaults    0 1
EOF

# 配置 hostname
echo "openeuler-riscv64" > "${ROOTFS_DIR}/etc/hostname"

# 配置 hosts
cat > "${ROOTFS_DIR}/etc/hosts" << 'EOF'
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
EOF

# 配置 resolv.conf
cat > "${ROOTFS_DIR}/etc/resolv.conf" << 'EOF'
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

# 配置 sshd
mkdir -p "${ROOTFS_DIR}/etc/ssh"
echo "PasswordAuthentication yes" >> "${ROOTFS_DIR}/etc/ssh/sshd_config"
echo "PermitRootLogin yes" >> "${ROOTFS_DIR}/etc/ssh/sshd_config"

# 配置 root 密码（默认为 openEuler12#$，请登录后修改）
echo "root:openEuler12#$" | chroot "${ROOTFS_DIR}" chpasswd

# 配置 systemd
ln -sf /usr/lib/systemd/systemd "${ROOTFS_DIR}/init"
chroot "${ROOTFS_DIR}" systemctl enable sshd.service 2>/dev/null || true
chroot "${ROOTFS_DIR}" systemctl enable NetworkManager.service 2>/dev/null || true
chroot "${ROOTFS_DIR}" systemctl enable systemd-networkd.service 2>/dev/null || true
chroot "${ROOTFS_DIR}" systemctl enable systemd-resolved.service 2>/dev/null || true
chroot "${ROOTFS_DIR}" systemctl enable systemd-timesyncd.service 2>/dev/null || true

# 配置时间同步
cat > "${ROOTFS_DIR}/etc/systemd/timesyncd.conf" << 'TIMESYNCEOF'
[Time]
NTP=ntp.aliyun.com ntp.tencent.com
FallbackNTP=0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org
TIMESYNCEOF

# 创建网络配置
mkdir -p "${ROOTFS_DIR}/etc/systemd/network"
cat > "${ROOTFS_DIR}/etc/systemd/network/20-wired.network" << 'NETWORKEOF'
[Match]
Name=en*

[Network]
DHCP=yes
NETWORKEOF

echo "基本系统配置完成"

# 配置代理环境变量
echo "配置代理环境变量..."
cat >> "${ROOTFS_DIR}/etc/profile.d/proxy.sh" << 'PROXYEOF'
export https_proxy=http://10.200.2.1:8586
export http_proxy=http://10.200.2.1:8586
export all_proxy=socks5://10.200.2.1:8585
export no_proxy=localhost,127.0.0.1
PROXYEOF
chmod +x "${ROOTFS_DIR}/etc/profile.d/proxy.sh"

# 下载 stream.c 文件
echo "下载 stream.c 文件到 /root/..."
chroot "${ROOTFS_DIR}" /bin/bash -c "source /etc/profile.d/proxy.sh && wget -O /root/stream.c https://www.cs.virginia.edu/stream/FTP/Code/stream.c"

echo "代理配置和文件下载完成"

# 清理 rpm 数据
rm -rf "${ROOTFS_DIR}/var/cache/dnf"
rm -rf "${ROOTFS_DIR}/var/lib/dnf"
rm -rf "${ROOTFS_DIR}/var/log/yum.log"
rm -rf "${ROOTFS_DIR}/var/log/dnf.rpm.log"

# 创建 ext4 镜像
echo "创建 ext4 文件系统镜像..."
ROOTFS_SIZE=$(du -sm "${ROOTFS_DIR}" | cut -f1)
IMG_SIZE=$((ROOTFS_SIZE + 2048))  # 预留 2GB 空间

echo "rootfs 实际大小: ${ROOTFS_SIZE}MB"
echo "镜像总大小: ${IMG_SIZE}MB (预留 2GB)"

TEMP_IMG="/tmp/rootfs_temp.img"
dd if=/dev/zero of="${TEMP_IMG}" bs=1M count="${IMG_SIZE}" 2>/dev/null
mkfs.ext4 -F "${TEMP_IMG}" 2>/dev/null

# 挂载并复制文件
MOUNT_DIR="/tmp/rootfs_mount"
mkdir -p "${MOUNT_DIR}"
mount -o loop "${TEMP_IMG}" "${MOUNT_DIR}"

cp -a "${ROOTFS_DIR}"/* "${MOUNT_DIR}/"

# 设置权限
chmod 1777 "${MOUNT_DIR}/tmp"
chmod 755 "${MOUNT_DIR}"

umount "${MOUNT_DIR}"
rm -rf "${MOUNT_DIR}"

# 使用 zst 压缩镜像
echo "使用 zst 压缩镜像..."
zstd -f "${TEMP_IMG}" -o "${ROOTFS_IMG}"
rm -f "${TEMP_IMG}"

echo "img.zst 镜像创建完成: ${ROOTFS_IMG}"

# 打包 tar.gz
echo "打包 rootfs..."
tar -czf "${ROOTFS_TARBALL}" -C "${ROOTFS_DIR}" .

echo "tar.gz 打包完成: ${ROOTFS_TARBALL}"

# 显示文件信息
echo "========================================="
echo "构建完成！"
echo "========================================="
echo "img.zst 镜像: ${ROOTFS_IMG}"
du -h "${ROOTFS_IMG}"
echo ""
echo "tar.gz 包: ${ROOTFS_TARBALL}"
du -h "${ROOTFS_TARBALL}"
echo "========================================="