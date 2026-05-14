#!/bin/bash
#
# 发行版配置
# 用法: source config.sh <distro>
# 支持的发行版: openEuler-24.03-LTS-SP3, openEuler-24.03-LTS-SP2, openruyi
#

set -euo pipefail

DISTRO="${1:-openruyi-rva23}"

case "${DISTRO}" in
    openEuler-24.03-LTS-SP3)
        DISTRO_NAME="openEuler"
        DISTRO_VERSION="24.03-LTS-SP3"
        ARCH="riscv64"
        PROFILE="rva20"
        HOSTNAME="riscv64"
        ROOT_PASSWORD="openEuler12#\$"
        NTP_SERVERS="ntp.aliyun.com ntp.tencent.com"
        FALLBACK_NTP="0.pool.ntp.org 1.pool.ntp.org"
        PROXY_HTTP="http://10.200.1.1:8888"
        PROXY_HTTPS="http://10.200.1.1:8888"
        PROXY_SOCKS="socks5://10.200.1.1:8585"
        INSTALL_MODE="group"
        INSTALL_TARGET="Minimal Install"
        REPO_URL="https://fast-mirror.isrc.ac.cn/openeuler/openEuler-24.03-LTS-SP3/everything/riscv64/rva20/riscv64/"
        EXTRA_PACKAGES="systemd-timesyncd"
        ;;
    openEuler-24.03-LTS-SP2)
        DISTRO_NAME="openEuler"
        DISTRO_VERSION="24.03-LTS-SP2"
        ARCH="riscv64"
        PROFILE="rva20"
        HOSTNAME="riscv64"
        ROOT_PASSWORD="openEuler12#\$"
        NTP_SERVERS="ntp.aliyun.com ntp.tencent.com"
        FALLBACK_NTP="0.pool.ntp.org 1.pool.ntp.org"
        PROXY_HTTP="http://10.200.1.1:8888"
        PROXY_HTTPS="http://10.200.1.1:8888"
        PROXY_SOCKS="socks5://10.200.1.1:8585"
        INSTALL_MODE="group"
        INSTALL_TARGET="Minimal Install"
        EXTRA_PACKAGES="systemd-timesyncd"
        ;;
    openruyi-rva23)
        DISTRO_NAME="openRuyi"
        DISTRO_VERSION="unstable"
        ARCH="riscv64"
        PROFILE="rva23"
        DISPLAY_DISTRO_VERSION="RVA23"
        HOSTNAME="riscv64"
        ROOT_PASSWORD="openEuler12#\$"
        NTP_SERVERS="ntp.aliyun.com ntp.tencent.com"
        FALLBACK_NTP="0.pool.ntp.org 1.pool.ntp.org"
        PROXY_HTTP="http://10.200.1.1:8888"
        PROXY_HTTPS="http://10.200.1.1:8888"
        PROXY_SOCKS="socks5://10.200.1.1:8585"
        INSTALL_MODE="package"
        INSTALL_TARGET="openruyi-minimal"
        DNF_OPTS="--use-host-config"
        EXTRA_PACKAGES="systemd-timesyncd systemd libseccomp NetworkManager"
        ;;
    openruyi-rva20)
        DISTRO_NAME="openRuyi"
        DISTRO_VERSION="unstable"
        ARCH="riscv64"
        PROFILE="rva20"
        DISPLAY_DISTRO_VERSION="RVA20"
        HOSTNAME="riscv64"
        ROOT_PASSWORD="openEuler12#\$"
        NTP_SERVERS="ntp.aliyun.com ntp.tencent.com"
        FALLBACK_NTP="0.pool.ntp.org 1.pool.ntp.org"
        PROXY_HTTP="http://10.200.1.1:8888"
        PROXY_HTTPS="http://10.200.1.1:8888"
        PROXY_SOCKS="socks5://10.200.1.1:8585"
        INSTALL_MODE="package"
        INSTALL_TARGET="openruyi-minimal"
        DNF_OPTS="--use-host-config"
        EXTRA_PACKAGES="systemd-timesyncd systemd libseccomp NetworkManager"
        ;;
    *)
        echo "错误: 不支持的发行版 '${DISTRO}'"
        echo "支持的发行版: openEuler-24.03-LTS-SP3, openEuler-24.03-LTS-SP2, openruyi-rva23, openruyi-rva20"
        exit 1
        ;;
esac

# 导出配置
export DISTRO DISTRO_NAME DISTRO_VERSION ARCH PROFILE DISPLAY_DISTRO_VERSION REPO_URL
export NTP_SERVERS FALLBACK_NTP PROXY_HTTP PROXY_HTTPS PROXY_SOCKS
export INSTALL_MODE INSTALL_TARGET DNF_OPTS EXTRA_PACKAGES
export HOSTNAME ROOT_PASSWORD
