# Rootfs 构建

自动化构建 RISC-V64 架构 rootfs 的流水线和脚本。

## 支持的发行版

| 发行版 | 架构 | 配置文件 |
|--------|------|----------|
| openEuler 24.03 SP2 | riscv64 (RVA20) | `openeuler` (默认) |
| openRuyi | riscv64 (RVA23) | `openruyi` |

## 功能

- ✅ 根据 `base.list` 安装指定软件包
- ✅ 生成 `{distro}-rootfs.img.zst`（zstd 压缩的 ext4 镜像）
- ✅ 生成 `{distro}-rootfs.tar.gz`（tar.gz 压缩包）
- ✅ 支持 Docker 构建和本地直接构建
- ✅ GitHub Actions 自动构建

**注意**：本 rootfs 不包含内核，需要单独准备内核镜像和 initrd。

## 目录结构

```
RAVA_ROOTFS/
├── Dockerfile                    # openEuler Docker 镜像
├── Dockerfile.openruyi           # openRuyi Docker 镜像
├── build-rootfs.sh               # rootfs 构建核心脚本
├── config.sh                     # 发行版配置
├── local-build.sh                # Docker 本地构建入口
├── base.list                     # 软件包列表
├── quickstart.sh                 # 快速开始指南
├── .github/workflows/
│   └── build-rootfs.yml          # GitHub Actions 流水线
├── README.md                     # 本文档
└── output/                       # 构建产物（构建后生成）
```

## 快速开始

### 方式 1：Docker 构建（推荐）

```bash
# 构建 openEuler (默认)
chmod +x local-build.sh
./local-build.sh

# 构建 openRuyi
./local-build.sh openruyi
```

### 方式 2：本地直接构建

```bash
# openEuler
sudo bash build-rootfs.sh openeuler

# openRuyi
sudo bash build-rootfs.sh openruyi
```

### 方式 3：GitHub Actions

推送到 `main`/`master` 分支自动触发，或在 Actions 页面手动触发。

## 构建产物

| 发行版 | 镜像文件 | 压缩包 |
|--------|----------|--------|
| openEuler | `openeuler-rootfs.img.zst` | `openeuler-rootfs.tar.gz` |
| openRuyi | `openruyi-rootfs.img.zst` | `openruyi-rootfs.tar.gz` |

## 使用 rootfs

### QEMU 启动

```bash
# 解压镜像
zstd -d output/openeuler-rootfs.img.zst -o output/openeuler-rootfs.img

# 启动（需要内核和 initrd）
qemu-system-riscv64 \
    -M virt -m 2G -smp 4 \
    -kernel /path/to/Image \
    -initrd /path/to/initrd \
    -device virtio-blk-device,drive=rootfs \
    -drive if=none,file=output/openeuler-rootfs.img,id=rootfs,format=raw \
    -append "root=/dev/vda ro console=ttyS0" \
    -nographic
```

### 真机启动

```bash
zstd -d output/openeuler-rootfs.img.zst -o output/openeuler-rootfs.img
dd if=output/openeuler-rootfs.img of=/dev/sdX bs=1M status=progress
```

## 默认配置

| 项目 | openEuler (RVA20) | openRuyi (RVA23) |
|------|-----------|----------|
| 主机名 | openeuler-rva20 | openruyi-rva23 |
| root 密码 | openEuler12#$ | openEuler12#$ |
| SSH | 允许 root 密码登录 | 允许 root 密码登录 |
| 网络 | DHCP 自动获取 | DHCP 自动获取 |
| 分区 | 单一 root 分区 (/dev/vda) | 单一 root 分区 (/dev/vda) |
| 时间同步 | systemd-timesyncd | systemd-timesyncd |
| 代理 | 已配置 (/etc/profile.d/proxy.sh) | 已配置 |
| 预装文件 | /root/stream.c | /root/stream.c |

## 自定义

### 修改软件包列表

编辑 `base.list`，每行一个包名：

```
NetworkManager
openssh-server
vim-enhanced
```

### 修改发行版配置

编辑 `config.sh`，添加或修改发行版配置：

```bash
mydistro)
    DISTRO_NAME="MyDistro"
    DISTRO_VERSION="1.0"
    ARCH="riscv64"
    PROFILE="myprofile"
    CONTAINER_IMAGE="myrepo/myimage:tag"
    REPO_URL="https://myrepo.example.com/path"
    ...
    ;;
```

## 常见问题

**Q: 构建失败，网络问题？**

A: 替换为国内镜像源，在 `config.sh` 中修改 `REPO_URL`。

**Q: Docker 权限问题？**

A: 确保使用 `--privileged` 标志运行容器。

**Q: 镜像大小过大？**

A: 在 `build-rootfs.sh` 中添加清理步骤：
```bash
rm -rf ${ROOTFS_DIR}/usr/share/locale/*
rm -rf ${ROOTFS_DIR}/usr/share/doc/*
```

**Q: 内核相关？**

A: 本 rootfs 不包含内核，请自行准备内核和 initrd。

## 环境要求

- Docker（方式 1）或 root 权限（方式 2）
- 磁盘空间 > 5GB
- 网络连接（访问软件源）

## License

MIT
