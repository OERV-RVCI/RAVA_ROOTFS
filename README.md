# openEuler RISC-V Rootfs 构建

本仓库包含制作 openEuler 24.03 SP3 RISC-V 架构 rootfs 的流水线和脚本。

## 功能

- 构建 openEuler 24.03 SP3 RISC-V rootfs
- 安装 "Minimal Install" 包组
- 生成 ext4 文件系统镜像
- 打包 tar.xz 压缩包

## 目录结构

```
RAVA_ROOTFS/
├── Dockerfile                    # Docker 镜像构建文件
├── build-rootfs.sh               # rootfs 构建脚本
├── .github/workflows/
│   └── build-rootfs.yml          # GitHub Actions 流水线
└── README.md                     # 本文档
```

## 本地构建

### 方法 1: 使用本地测试脚本（推荐）

```bash
chmod +x local-build.sh
./local-build.sh
```

这个脚本会自动完成以下步骤：
1. 构建 Docker 镜像
2. 运行 rootfs 构建脚本
3. 生成输出文件

### 方法 2: 手动构建

#### 1. 构建 Docker 镜像

```bash
docker build -t rootfs-builder:latest .
```

#### 2. 运行构建脚本

```bash
mkdir -p output
docker run --rm --privileged -v $(pwd)/output:/workspace rootfs-builder:latest bash /workspace/build-rootfs.sh
```

### 3. 构建产物

构建完成后，`output/` 目录下会生成：

- `openeuler-24.03-SP3-riscv64-rootfs.ext4` - ext4 文件系统镜像
- `openeuler-24.03-SP3-riscv64-rootfs.tar.xz` - rootfs 压缩包

## GitHub Actions 构建

触发方式：

1. **自动触发**: 推送到 main/master 分支
2. **手动触发**: 在 Actions 页面手动触发，可指定版本参数

构建产物会自动上传到 GitHub Actions artifacts，保留 30 天。

## 使用 rootfs

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

### 真机启动

将 ext4 镜像写入存储设备：

```bash
dd if=openeuler-24.03-SP3-riscv64-rootfs.ext4 of=/dev/sdX bs=1M status=progress
```

## 默认配置

- **用户**: root
- **密码**: openeuler（登录后请修改）
- **SSH**: 已启用，允许 root 登录
- **网络**: DHCP 自动获取

## 自定义

修改 `build-rootfs.sh` 中的变量：

```bash
OPENEULER_RELEASE="24.03"     # 发行版本
OPENEULER_VERSION="SP3"       # 更新版本
ARCH="riscv64"                # 架构
```

修改软件包列表：

在 `dnf install` 命令中添加/删除需要的包。

## 注意事项

1. 需要 root 权限运行（用于创建设备文件）
2. 构建过程需要约 2-5GB 磁盘空间
3. 生成的 ext4 镜像大小约为 1-2GB

## License

MIT