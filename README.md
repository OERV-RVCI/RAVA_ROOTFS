# openEuler RISC-V Rootfs 构建

自动化构建 openEuler 24.03 SP2 RISC-V 架构 rootfs 的流水线和脚本。

## 功能

- ✅ 根据 `base.list` 安装指定软件包（124 个包）
- ✅ 生成 `openeuler-rootfs.img.zst`（zstd 压缩的 ext4 镜像，单一 root 分区）
- ✅ 生成 `openeuler-rootfs.tar.gz`（tar.gz 压缩包）
- ✅ 支持 Docker 构建和本地直接构建
- ✅ GitHub Actions 自动构建

**注意**：本 rootfs 不包含内核，需要单独准备内核镜像和 initrd。

## 目录结构

```
RAVA_ROOTFS/
├── Dockerfile                    # Docker 镜像构建文件
├── build-rootfs.sh               # rootfs 构建核心脚本
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
chmod +x local-build.sh
./local-build.sh
```

- 隔离环境，不污染宿主机
- 保证构建一致性

### 方式 2：本地直接构建

```bash
# 需要 root 权限和必要工具（dnf, qemu-img, e2fsprogs, zstd）
sudo bash build-rootfs.sh
```

- 不需要 Docker，更快
- 需要 root 权限

### 方式 3：GitHub Actions

推送到 `main`/`master` 分支自动触发，或在 Actions 页面手动触发。

## 构建产物

构建完成后，`output/` 目录下会生成：

| 文件 | 说明 |
|------|------|
| `openeuler-rootfs.img.zst` | zstd 压缩的 ext4 镜像 |
| `openeuler-rootfs.tar.gz` | tar.gz 压缩包 |

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
zstd -d openeuler-rootfs.img.zst -o openeuler-rootfs.img
dd if=openeuler-rootfs.img of=/dev/sdX bs=1M status=progress
```

## 默认配置

| 项目 | 值 |
|------|-----|
| 用户 | root |
| 密码 | openEuler12#$（登录后请修改） |
| SSH | 允许 root 密码登录 |
| 网络 | DHCP 自动获取 |
| 分区 | 单一 root 分区（/dev/vda） |
| 时间同步 | systemd-timesyncd（阿里云/腾讯云 NTP） |
| 代理 | 已配置（`/etc/profile.d/proxy.sh`） |
| 预装文件 | `/root/stream.c`（stream 基准测试工具源码） |

## 自定义

### 修改软件包列表

编辑 `base.list`，每行一个包名：

```
NetworkManager
openssh-server
vim-enhanced
```

### 修改默认密码

在 `build-rootfs.sh` 中修改：

```bash
echo "root:your_new_password" | chroot "${ROOTFS_DIR}" chpasswd
```

### 修改代理配置

在 `build-rootfs.sh` 中修改 proxy.sh 的生成部分。

## 常见问题

**Q: 构建失败，网络问题？**

A: 替换为国内镜像源，在 `build-rootfs.sh` 中修改 REPO_URL。

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
- 网络连接（访问 openEuler 软件源）

## License

MIT
