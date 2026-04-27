#!/bin/bash
#
# 发行版配置
# 用法: source config.sh <distro>
# 支持的发行版: openeuler, openruyi
#

set -euo pipefail

DISTRO="${1:-openeuler}"

case "${DISTRO}" in
    openeuler)
        DISTRO_NAME="openEuler"
        DISTRO_VERSION="24.03-lts-sp2"
        ARCH="riscv64"
        PROFILE="rva20"
        CONTAINER_IMAGE="openeuler/openeuler:${DISTRO_VERSION}"
        REPO_BASE="https://repo.openeuler.org"
        REPO_URL="${REPO_BASE}/openEuler-${DISTRO_VERSION}/OS/${ARCH}/"
        PACKAGE_MANAGER="dnf"
        HOSTNAME="openeuler-rva20"
        ROOT_PASSWORD="openEuler12#\$"
        NTP_SERVERS="ntp.aliyun.com ntp.tencent.com"
        FALLBACK_NTP="0.pool.ntp.org 1.pool.ntp.org"
        PROXY_HTTP="http://10.200.2.1:8586"
        PROXY_HTTPS="http://10.200.2.1:8586"
        PROXY_SOCKS="socks5://10.200.2.1:8585"
        INSTALL_MODE="group"
        INSTALL_TARGET="Minimal Install"
        ;;
    openruyi)
        DISTRO_NAME="openRuyi"
        DISTRO_VERSION="unstable"
        ARCH="riscv64"
        PROFILE="rva23"
        DISPLAY_DISTRO_VERSION="RVA23"
        CONTAINER_IMAGE="git.openruyi.cn/openruyi/creek-x86-64:latest"
        REPO_BASE="https://boat.openruyi.cn"
        REPO_URL="${REPO_BASE}/unstable/rva23"
        PACKAGE_MANAGER="dnf"
        HOSTNAME="openruyi-rva23"
        ROOT_PASSWORD="openEuler12#\$"
        NTP_SERVERS="ntp.aliyun.com ntp.tencent.com"
        FALLBACK_NTP="0.pool.ntp.org 1.pool.ntp.org"
        PROXY_HTTP="http://10.200.2.1:8586"
        PROXY_HTTPS="http://10.200.2.1:8586"
        PROXY_SOCKS="socks5://10.200.2.1:8585"
        INSTALL_MODE="package"
        INSTALL_TARGET="openruyi-minimal"
        DNF_OPTS="--use-host-config"
        ;;
    *)
        echo "错误: 不支持的发行版 '${DISTRO}'"
        echo "支持的发行版: openeuler, openruyi"
        exit 1
        ;;
esac

# 导出配置
export DISTRO DISTRO_NAME DISTRO_VERSION ARCH PROFILE CONTAINER_IMAGE
export REPO_BASE REPO_URL PACKAGE_MANAGER HOSTNAME ROOT_PASSWORD
export NTP_SERVERS FALLBACK_NTP PROXY_HTTP PROXY_HTTPS PROXY_SOCKS
export INSTALL_MODE INSTALL_TARGET DNF_OPTS
