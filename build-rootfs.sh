#!/bin/bash
#
# Rootfs 构建脚本
# 支持多种发行版: openeuler, openruyi
#
# 用法:
#   容器模式: docker run --privileged ... build-rootfs.sh [distro]
#   本地模式: sudo bash build-rootfs.sh [distro]
#
# 发行版参数:
#   openeuler  - openEuler 24.03 SP2 RISC-V64 (RVA20) (默认)
#   openruyi   - openRuyi RISC-V64 (RVA23)
#

set -euo pipefail

# ============================================================================
# 加载配置
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISTRO="${1:-openeuler}"

source "${SCRIPT_DIR}/config.sh" "${DISTRO}"

# ============================================================================
# 环境检测
# ============================================================================

detect_environment() {
    if [ -f "/.dockerenv" ]; then
        ENV_MODE="container"
        WORKSPACE="${OUTPUT_DIR:-/output}"
    else
        ENV_MODE="local"
        WORKSPACE="$(pwd)"
    fi

    ROOTFS_DIR="${WORKSPACE}/rootfs"
    ROOTFS_IMG="${WORKSPACE}/${DISTRO}-rootfs.img.zst"
    ROOTFS_TARBALL="${WORKSPACE}/${DISTRO}-rootfs.tar.gz"
}

# ============================================================================
# 工具函数
# ============================================================================

log() {
    echo "[${DISTRO_NAME}] $*"
}

log_section() {
    echo ""
    echo "========================================="
    echo " $1"
    echo "========================================="
}

check_requirements() {
    local missing=()
    local cmds=("dnf" "mkfs.ext4" "zstd" "mount" "umount" "dd" "tar" "wget")

    for cmd in "${cmds[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        log "错误: 缺少必要工具: ${missing[*]}"
        if [ "$ENV_MODE" = "local" ]; then
            log "请安装: sudo dnf install -y dnf e2fsprogs zstd util-linux wget tar"
        fi
        exit 1
    fi

    if [ "$ENV_MODE" = "local" ] && [ "$EUID" -ne 0 ]; then
        log "错误: 本地模式需要 root 权限"
        log "请使用: sudo $0"
        exit 1
    fi
}

MOUNTS_CLEANED=false

cleanup_mounts() {
    if $MOUNTS_CLEANED; then return; fi
    MOUNTS_CLEANED=true

    for m in "${ROOTFS_DIR}/dev/pts" "${ROOTFS_DIR}/dev" "${ROOTFS_DIR}/sys" "${ROOTFS_DIR}/proc"; do
        umount "$m" 2>/dev/null || true
    done
    if [ -n "${TEMP_MOUNT_DIR:-}" ] && [ -d "${TEMP_MOUNT_DIR}" ]; then
        umount "${TEMP_MOUNT_DIR}" 2>/dev/null || true
        rm -rf "${TEMP_MOUNT_DIR}"
    fi
    rm -f "${TEMP_IMG:-}"
}

trap cleanup_mounts EXIT

# ============================================================================
# 构建步骤
# ============================================================================

setup_directories() {
    log "清理旧的构建产物..."
    rm -rf "${ROOTFS_DIR}"
    rm -f "${ROOTFS_IMG}" "${ROOTFS_TARBALL}"

    mkdir -p "${ROOTFS_DIR}"/{dev,sys,proc,dev/pts}
}

install_packages() {
    log "安装目标: ${INSTALL_TARGET} (模式: ${INSTALL_MODE})"

    mount -t proc proc "${ROOTFS_DIR}/proc"
    mount -t sysfs sysfs "${ROOTFS_DIR}/sys"
    mount --bind /dev "${ROOTFS_DIR}/dev"
    mount -t devpts devpts "${ROOTFS_DIR}/dev/pts"

    log "安装软件包..."
    if [ "${INSTALL_MODE}" = "group" ]; then
        dnf group install -y \
            --installroot="${ROOTFS_DIR}" \
            --forcearch="${ARCH}" \
            --nodocs \
            "${INSTALL_TARGET}"
    else
        dnf install -y \
            --installroot="${ROOTFS_DIR}" \
            --forcearch="${ARCH}" \
            --nodocs \
            ${DNF_OPTS:-} \
            "${INSTALL_TARGET}"
    fi

    # 安装额外软件包
    if [ -n "${EXTRA_PACKAGES:-}" ]; then
        log "安装额外软件包: ${EXTRA_PACKAGES}"
        dnf install -y \
            --installroot="${ROOTFS_DIR}" \
            --forcearch="${ARCH}" \
            --nodocs \
            ${DNF_OPTS:-} \
            ${EXTRA_PACKAGES}
    fi

    log "软件包安装完成"
}

configure_system() {
    log "配置基本系统..."

    cat > "${ROOTFS_DIR}/etc/fstab" << 'EOF'
# /etc/fstab
/dev/vda  /  ext4  defaults  0 1
EOF

    echo "${HOSTNAME}" > "${ROOTFS_DIR}/etc/hostname"

    cat > "${ROOTFS_DIR}/etc/hosts" << 'EOF'
127.0.0.1   localhost localhost.localdomain
::1         localhost localhost.localdomain
EOF

    mkdir -p "${ROOTFS_DIR}/etc/ssh"
    {
        echo "PasswordAuthentication yes"
        echo "PermitRootLogin yes"
    } >> "${ROOTFS_DIR}/etc/ssh/sshd_config"

    echo "root:${ROOT_PASSWORD}" | chroot "${ROOTFS_DIR}" chpasswd

    ln -sf /usr/lib/systemd/systemd "${ROOTFS_DIR}/init"
    chroot "${ROOTFS_DIR}" systemctl enable sshd.service 2>/dev/null || true
    chroot "${ROOTFS_DIR}" systemctl enable NetworkManager.service 2>/dev/null || true

    # 配置 NTP 时间同步（如果 systemd-timesyncd 存在）
    if [ -d "${ROOTFS_DIR}/etc/systemd" ]; then
        mkdir -p "${ROOTFS_DIR}/etc/systemd"
        cat > "${ROOTFS_DIR}/etc/systemd/timesyncd.conf" << EOF
[Time]
NTP=${NTP_SERVERS}
FallbackNTP=${FALLBACK_NTP}
EOF
    fi

    log "基本系统配置完成"
}

configure_network() {
    log "配置代理和网络..."

    cat > "${ROOTFS_DIR}/etc/profile.d/proxy.sh" << EOF
export https_proxy=${PROXY_HTTPS}
export http_proxy=${PROXY_HTTP}
export all_proxy=${PROXY_SOCKS}
EOF
    chmod +x "${ROOTFS_DIR}/etc/profile.d/proxy.sh"

    log "下载 stream.c..."
    mkdir -p "${ROOTFS_DIR}/root"
    wget -q -O "${ROOTFS_DIR}/root/stream.c" \
        https://www.cs.virginia.edu/stream/FTP/Code/stream.c || \
        log "警告: stream.c 下载失败，跳过"

    log "网络和代理配置完成"
}

cleanup_rootfs() {
    log "清理包管理器缓存..."
    rm -rf "${ROOTFS_DIR}/var/cache/dnf"
    rm -rf "${ROOTFS_DIR}/var/lib/dnf"
    rm -f "${ROOTFS_DIR}/var/log/yum.log"
    rm -f "${ROOTFS_DIR}/var/log/dnf.rpm.log"

    cleanup_mounts
}

create_image() {
    log_section "创建 ext4 镜像"

    local rootfs_size
    rootfs_size=$(du -sm "${ROOTFS_DIR}" | cut -f1)
    local img_size=$((rootfs_size + 2048))

    log "rootfs 大小: ${rootfs_size}MB, 镜像大小: ${img_size}MB (含 2GB 预留)"

    TEMP_IMG=$(mktemp /tmp/rootfs-XXXXXX.img)
    TEMP_MOUNT_DIR=$(mktemp -d /tmp/rootfs-mount-XXXX)

    dd if=/dev/zero of="${TEMP_IMG}" bs=1M count="${img_size}" status=none
    mkfs.ext4 -F "${TEMP_IMG}" >/dev/null

    mount -o loop "${TEMP_IMG}" "${TEMP_MOUNT_DIR}"
    cp -a "${ROOTFS_DIR}/." "${TEMP_MOUNT_DIR}/"
    sync

    umount "${TEMP_MOUNT_DIR}"
    rmdir "${TEMP_MOUNT_DIR}"
    TEMP_MOUNT_DIR=""

    log "压缩镜像 (zstd)..."
    zstd -f "${TEMP_IMG}" -o "${ROOTFS_IMG}"

    log "镜像创建完成: ${ROOTFS_IMG}"
}

create_tarball() {
    log_section "创建 tar.gz 压缩包"

    tar -czf "${ROOTFS_TARBALL}" -C "${ROOTFS_DIR}" .

    log "压缩包创建完成: ${ROOTFS_TARBALL}"
}

show_summary() {
    log_section "构建完成！"
    log "发行版: ${DISTRO_NAME} ${DISTRO_VERSION} (${PROFILE})"
    log "镜像:   ${ROOTFS_IMG}"
    log "压缩包: ${ROOTFS_TARBALL}"
    echo ""
    du -sh "${ROOTFS_IMG}" "${ROOTFS_TARBALL}"
    echo "========================================="
}

# ============================================================================
# 主流程
# ============================================================================

main() {
    detect_environment
    check_requirements

    # 设置显示版本
    if [ -n "${DISPLAY_DISTRO_VERSION:-}" ]; then
        DISPLAY_VER="${DISPLAY_DISTRO_VERSION}"
    else
        DISPLAY_VER="${DISTRO_VERSION}"
    fi

    log_section "${DISTRO_NAME} Rootfs 构建"
    log "发行版: ${DISTRO_NAME}"
    if [ -n "${DISPLAY_VER}" ]; then
        log "版本:   ${DISPLAY_VER}"
    fi
    log "架构:   ${ARCH} (${PROFILE})"
    log "模式:   ${ENV_MODE}"
    log "输出:   ${WORKSPACE}"

    setup_directories
    install_packages
    configure_system
    configure_network
    cleanup_rootfs
    create_image
    create_tarball
    show_summary
}

main "$@"
