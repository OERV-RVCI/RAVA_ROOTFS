# openEuler RISC-V Rootfs 构建流水线

## 项目概览

本项目为 `/home/snail/Work/github/wangliu-iscas/OERV-RVCI/RAVA_ROOTFS` 仓库，提供完整的 openEuler 24.03 SP2 RISC-V 架构 rootfs 构建流水线。

## 功能特性

✅ 自动化构建流程（Docker + GitHub Actions）
✅ 根据 base.list 安装指定的软件包列表
✅ 生成 img.zst 镜像（zst 压缩）（单一 root 分区）
✅ 生成 tar.xz 压缩包
✅ 完整的文档和示例

**注意**:
- 本 rootfs 不包含内核软件包，需要单独准备内核镜像和 initrd
- 默认使用单一 root 分区（/dev/vda）
- 默认 root 密码为 openEuler12#$

## 项目结构

```
RAVA_ROOTFS/
├── Dockerfile                            # Docker 镜像构建文件 (552 bytes)
├── build-rootfs.sh                       - rootfs 构建核心脚本 (5.4K)
├── local-build.sh                        - 本地测试构建脚本 (1.3K)
├── quickstart.sh                         - 快速开始指南 (1.9K)
├── README.md                             - 项目说明文档 (2.7K)
├── BUILD.md                              - 详细构建文档 (5.3K)
├── .gitignore                            - Git 忽略配置
└── .github/workflows/
    └── build-rootfs.yml                  - GitHub Actions 流水线 (2.3K)
```

## 核心文件说明

### 1. Dockerfile

- 基础镜像: `openeuler/openeuler:24.03-lts-sp2` (官方镜像)
- 安装工具: dnf, qemu-img, e2fsprogs 等
- 复制构建脚本并设置执行权限

**优势**: 使用官方镜像，稳定可靠，无需配置私有仓库

### 2. build-rootfs.sh

主要功能：
- 创建 rootfs 目录结构
- 配置 openEuler 软件源
- 从 base.list 读取并安装软件包
- 配置系统（fstab、hostname、网络、SSH）
- 创建 img.zst 镜像（zst 压缩）（单一 root 分区）
- 打包 tar.xz

关键配置：
```bash
ARCH="riscv64"
REPO_URL="https://repo.openeuler.org/openEuler-24.03/detached/YUM/SP2/standard_riscv64/"
```

默认登录：
- 用户: root
- 密码: openEuler12#$
- 分区: 单一 root 分区（/dev/vda）
- 时间同步: 已启用 systemd-timesyncd
- 代理配置: 已设置默认代理（`/etc/profile.d/proxy.sh`）
- 预下载文件: `/root/stream.c`

### 3. local-build.sh

简化本地构建流程：
1. 检查 Docker 环境
2. 构建 Docker 镜像
3. 运行 rootfs 构建
4. 显示输出文件

### 4. GitHub Actions 流水线

触发条件：
- 推送到 main/master 分支
- 手动触发（可指定版本参数）

构建流程：
1. 从 Docker Hub 拉取 `openeuler/openeuler:24.03-lts-sp2`
2. 设置 QEMU 和 Docker BuildX
3. 构建并运行 rootfs
4. 上传构建产物（保留 30 天）

**优势**: 使用官方镜像，无需配置私有仓库凭据

## 使用方法

### 本地快速构建

```bash
cd /home/snail/Work/github/wangliu-iscas/OERV-RVCI/RAVA_ROOTFS
./local-build.sh
```

### 查看 Quickstart

```bash
./quickstart.sh
```

### GitHub Actions 构建

1. 推送代码到 main/master 分支自动触发
2. 或在 GitHub Actions 页面手动触发

## 构建产物

位置: `output/` 目录

- `openeuler-rootfs.img.zst` - img.zst 镜像（zst 压缩）
- `openeuler-rootfs.tar.gz` - rootfs 压缩包（gz 压缩）

## QEMU 测试示例

**需要先准备内核和 initrd**

```bash
qemu-system-riscv64 \
  -M virt -m 2G -smp 4 \
  -kernel /path/to/Image \
  -initrd /path/to/initrd \
  -device virtio-blk-device,drive=rootfs \
  -drive if=none,file=output/openeuler-rootfs.img.zst,id=rootfs \
  -append "root=/dev/vda ro console=ttyS0" \
  -nographic
```

## 自定义配置

### 修改软件包列表

编辑 `base.list` 文件，添加或删除需要的包：

```
NetworkManager
openssh-server
vim-enhanced
git
```

### 修改默认密码

在 `build-rootfs.sh` 中修改:
```bash
echo "root:your_new_password" | chroot "${ROOTFS_DIR}" chpasswd
```

### 修改分区配置

在 `build-rootfs.sh` 的 fstab 中修改：
```bash
# 默认单一 root 分区
/dev/vda  /      ext4    defaults    0 1

# 如需多个分区，自行调整
```

## 环境要求

- Docker (推荐最新版本)
- 磁盘空间: > 5GB
- 网络连接: 访问 openEuler 软件源
- 权限: 需要特权模式（--privileged）

## 常见问题

### 构建失败: 网络问题

替换为国内镜像源:
```bash
REPO_URL="https://mirrors.huaweicloud.com/openeuler/openEuler-24.03/detached/YUM/SP2/standard_riscv64/"
```

### Docker 权限问题

确保使用 `--privileged` 标志运行容器。

### 镜像大小过大

清理不必要的内容:
```bash
rm -rf ${ROOTFS_DIR}/usr/share/locale/*
rm -rf ${ROOTFS_DIR}/usr/share/doc/*
```

### 内核相关问题

本 rootfs 不包含内核，请自行准备内核和 initrd。

## 下一步

1. 准备内核和 initrd
2. 提交代码到 GitHub
3. 推送到 main/master 分支触发构建
4. 从 GitHub Actions 下载构建产物
5. 在 QEMU 或真实硬件上测试

## 相关资源

- [openEuler 官方网站](https://www.openeuler.org/)
- [openEuler RISC-V](https://www.openeuler.org/zh/architecture/riscv/)
- [QEMU 文档](https://www.qemu.org/docs/master/system/target-riscv.html)
- [Linux 内核](https://www.kernel.org/)

---

**构建时间**: 2026-04-24
**版本**: 4.0
**维护者**: OERV-CI Team
**变更**:
- 使用 openeuler/openeuler:24.03-lts-sp2 官方镜像
- 移除对 hub.oepkgs.net 私有仓库的依赖
- 简化 GitHub Actions 流程
- 添加本地直接构建方式