# openEuler RISC-V Rootfs 构建

本仓库包含制作 openEuler 24.03 SP3 RISC-V 架构 rootfs 的流水线和脚本。

## 功能

- 构建 openEuler 24.03 SP3 RISC-V rootfs
- 根据 base.list 安装指定的软件包
- 生成 ext4 文件系统镜像（单一 root 分区）
- 打包 tar.xz 压缩包

## 目录结构

```
RAVA_ROOTFS/
├── Dockerfile                    # Docker 镜像构建文件（基于 openeuler:24.03-lts-sp2）
├── build-rootfs.sh               # rootfs 构建脚本（支持 Docker 和本地两种方式）
├── local-build.sh                # Docker 构建脚本
├── native-build.sh               # 本地直接构建脚本
├── base.list                     # 软件包列表（124 个包）
├── .github/workflows/
│   └── build-rootfs.yml          # GitHub Actions 流水线
├── README.md                     - 本文档
├── BUILD.md                      - 详细构建文档
├── KERNEL.md                     - 内核准备指南
└── PROJECT.md                    - 项目总览
```

## 本地构建

### 方式 1: 使用 Docker（推荐）

```bash
chmod +x local-build.sh
./local-build.sh
```

**优点**:
- 隔离环境，不污染宿主机
- 保证构建一致性
- 可在任何有 Docker 的机器上构建

### 方式 2: 直接运行（需要 root 权限）

```bash
chmod +x native-build.sh
sudo ./native-build.sh
```

**优点**:
- 不需要 Docker
- 更快（无 Docker 开销）

**缺点**:
- 需要 root 权限
- 可能影响宿主机系统

### 方式 3: 手动构建 Docker

```bash
docker build -t rootfs-builder:latest .
mkdir -p output
docker run --rm --privileged -v $(pwd)/output:/workspace rootfs-builder:latest
```

### 3. 构建产物

构建完成后，`output/` 目录下会生成：

- `openeuler-24.03-SP3-riscv64-rootfs.ext4` - ext4 文件系统镜像
- `openeuler-24.03-SP3-riscv64-rootfs.tar.xz` - rootfs 压缩包

## GitHub Actions 构建

**注意**: 使用 `openeuler/openeuler:24.03-lts-sp2` 官方镜像，无需配置私有仓库。

触发方式：

1. **自动触发**: 推送到 main/master 分支
2. **手动触发**: 在 Actions 页面手动触发，可指定版本参数

构建流程：
1. 从 Docker Hub 拉取 openeuler:24.03-lts-sp2 镜像
2. 构建并运行 rootfs
3. 上传构建产物（保留 30 天）

构建产物会自动上传到 GitHub Actions artifacts，保留 30 天。

## 使用 rootfs

**注意**: 本 rootfs 不包含内核，需要单独准备内核镜像和 initrd。详见 [KERNEL.md](KERNEL.md)。

### QEMU 启动

```bash
# 使用 ext4 镜像
qemu-system-riscv64 \
  -M virt \
  -m 2G \
  -smp 4 \
  -kernel /path/to/Image \
  -initrd /path/to/initrd \
  -device virtio-blk-device,drive=rootfs \
  -drive if=none,file=openeuler-24.03-SP3-riscv64-rootfs.ext4,id=rootfs,format=raw \
  -append "root=/dev/vda ro console=ttyS0" \
  -nographic
```

**内核准备**:

从 openEuler 下载 RISC-V 内核：
```bash
# 内核镜像
wget https://repo.openeuler.org/openEuler-24.03/detached/YUM/SP3/standard_riscv64/Packages/kernel-image-*.rpm
rpm2cpio kernel-image-*.rpm | cpio -idmv ./boot/Image

# initrd
wget https://repo.openeuler.org/openEuler-24.03/detached/YUM/SP3/standard_riscv64/Packages/kernel-modules-*.rpm
```

### 真机启动

将 ext4 镜像写入存储设备：

```bash
dd if=openeuler-24.03-SP3-riscv64-rootfs.ext4 of=/dev/sdX bs=1M status=progress
```

## 默认配置

- **用户**: root
- **密码**: openEuler12#$（登录后请修改）
- **SSH**: 已启用，允许 root 登录
- **网络**: DHCP 自动获取
- **分区**: 单一 root 分区（/dev/vda）

## 自定义

### 修改软件包列表

编辑 `base.list` 文件，添加或删除需要的软件包：

```
# base.list 示例
NetworkManager
openssh-server
openssh-clients
vim-enhanced
```

### 修改版本

编辑 `build-rootfs.sh`：

```bash
OPENEULER_RELEASE="24.03"     # 发行版本
OPENEULER_VERSION="SP3"       # 更新版本
ARCH="riscv64"                # 架构
```

### 修改默认密码

在 `build-rootfs.sh` 中修改：

```bash
echo "root:your_new_password" | chroot "${ROOTFS_DIR}" chpasswd
```

## 注意事项

1. 需要 root 权限运行（用于创建设备文件）
2. 构建过程需要约 2-5GB 磁盘空间
3. 生成的 ext4 镜像大小约为 1-2GB

## License

MIT