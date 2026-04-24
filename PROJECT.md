# openEuler RISC-V Rootfs 构建流水线

## 项目概览

本项目为 `/home/snail/Work/github/wangliu-iscas/OERV-RVCI/RAVA_ROOTFS` 仓库，提供完整的 openEuler 24.03 SP3 RISC-V 架构 rootfs 构建流水线。

## 功能特性

✅ 自动化构建流程（Docker + GitHub Actions）
✅ 支持本地测试和 CI/CD 集成
✅ 安装 "Minimal Install" 包组
✅ 生成 ext4 文件系统镜像
✅ 生成 tar.xz 压缩包
✅ 完整的文档和示例

## 项目结构

```
RAVA_ROOTFS/
├── Dockerfile                            # Docker 镜像构建文件 (552 bytes)
├── build-rootfs.sh                       # rootfs 构建核心脚本 (5.4K)
├── local-build.sh                        # 本地测试构建脚本 (1.3K)
├── quickstart.sh                         # 快速开始指南 (1.9K)
├── README.md                             # 项目说明文档 (2.7K)
├── BUILD.md                              # 详细构建文档 (5.3K)
├── .gitignore                            # Git 忽略配置
└── .github/workflows/
    └── build-rootfs.yml                  # GitHub Actions 流水线 (2.3K)
```

## 核心文件说明

### 1. Dockerfile

- 基础镜像: `hub.oepkgs.net/oerv-ci/openeuler:24.03-lts-sp1`
- 安装工具: dnf, qemu-img, e2fsprogs, systemd 等
- 复制构建脚本并设置执行权限

### 2. build-rootfs.sh

主要功能：
- 创建 rootfs 目录结构
- 配置 openEuler 软件源
- 安装 Minimal Install 包组（包含内核、systemd、NetworkManager、openssh 等）
- 配置系统（fstab、hostname、网络、SSH）
- 创建 ext4 文件系统镜像
- 打包 tar.xz

关键配置：
```bash
OPENEULER_RELEASE="24.03"
OPENEULER_VERSION="SP3"
ARCH="riscv64"
REPO_URL="https://repo.openeuler.org/openEuler-24.03/detached/YUM/SP3/standard_riscv64/"
```

默认登录：
- 用户: root
- 密码: openeuler

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
1. 设置 QEMU 和 Docker BuildX
2. 构建 RISC-V Docker 镜像
3. 登录到 hub.oepkgs.net
4. 运行 rootfs 构建
5. 上传构建产物（保留 30 天）

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

- `openeuler-24.03-SP3-riscv64-rootfs.ext4` - ext4 文件系统镜像
- `openeuler-24.03-SP3-riscv64-rootfs.tar.xz` - rootfs 压缩包

## QEMU 测试示例

```bash
qemu-system-riscv64 \
  -M virt -m 2G -smp 4 \
  -kernel /path/to/Image \
  -initrd /path/to/initrd \
  -device virtio-blk-device,drive=rootfs \
  -drive if=none,file=output/openeuler-24.03-SP3-riscv64-rootfs.ext4,id=rootfs \
  -append "root=/dev/vda ro console=ttyS0" \
  -nographic
```

## 自定义配置

### 修改版本

编辑 `build-rootfs.sh`:
```bash
OPENEULER_RELEASE="24.03"    # 修改为其他版本
OPENEULER_VERSION="SP3"      # 修改为其他更新
```

### 添加软件包

在 `build-rootfs.sh` 的 `dnf install` 中添加:
```bash
vim git docker
```

### 修改默认密码

在 `build-rootfs.sh` 中修改:
```bash
echo "root:your_new_password" | chroot "${ROOTFS_DIR}" chpasswd
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
REPO_URL="https://mirrors.huaweicloud.com/openeuler/openEuler-24.03/detached/YUM/SP3/standard_riscv64/"
```

### Docker 权限问题

确保使用 `--privileged` 标志运行容器。

### 镜像大小过大

清理不必要的内容:
```bash
rm -rf ${ROOTFS_DIR}/usr/share/locale/*
rm -rf ${ROOTFS_DIR}/usr/share/doc/*
```

## 下一步

1. 提交代码到 GitHub
2. 推送到 main/master 分支触发构建
3. 从 GitHub Actions 下载构建产物
4. 在 QEMU 或真实硬件上测试

## 相关资源

- [openEuler 官方网站](https://www.openeuler.org/)
- [openEuler RISC-V](https://www.openeuler.org/zh/architecture/riscv/)
- [QEMU 文档](https://www.qemu.org/docs/master/system/target-riscv.html)

---

**构建时间**: 2026-04-24
**版本**: 1.0
**维护者**: OERV-CI Team