# 内核准备指南

本 rootfs 不包含内核，需要单独准备内核镜像和 initrd。

## 方法 1: 从 openEuler 仓库下载

### 1.1 下载内核镜像包

```bash
# openEuler 24.03 SP3 RISC-V 内核镜像包
KERNEL_URL="https://repo.openeuler.org/openEuler-24.03/detached/YUM/SP3/standard_riscv64/Packages/"

# 下载 kernel-image 包
wget ${KERNEL_URL}/kernel-image-*.rpm

# 解压内核镜像
rpm2cpio kernel-image-*.rpm | cpio -idmv

# 内核镜像位置
cp boot/Image /path/to/qemu/Image
```

### 1.2 下载内核模块

```bash
# 下载 kernel-modules 包
wget ${KERNEL_URL}/kernel-modules-*.rpm
wget ${KERNEL_URL}/kernel-modules-core-*.rpm

# 如果需要 initrd，可以创建一个
mkdir -p /tmp/initrd-work
cd /tmp/initrd-work

# 从 rootfs 复制必要的模块
mkdir -p lib/modules
cp -a /path/to/rootfs/lib/modules/* lib/modules/

# 创建 initrd
find . | cpio -o -H newc | xz --check=crc32 > /path/to/qemu/initrd.img
```

## 方法 2: 从已安装的系统提取

### 2.1 从已安装的 RISC-V 系统提取

如果有一个正在运行的 openEuler RISC-V 系统：

```bash
# 在 RISC-V 系统上
sudo cp /boot/Image /tmp/

# 创建 initrd
sudo dracut --force /tmp/initrd.img
```

然后将文件传输到构建机器。

### 2.2 从 rootfs 内创建 initrd

在构建的 rootfs 内创建 initrd：

```bash
# 挂载 rootfs
mkdir -p /mnt/rootfs
mount -o loop openeuler-24.03-SP3-riscv64-rootfs.ext4 /mnt/rootfs

# chroot 进入
chroot /mnt/rootfs

# 创建 initrd
dracut --force /boot/initramfs-$(uname -r).img

# 复制出来
exit
cp /mnt/rootfs/boot/initramfs-*.img /path/to/qemu/initrd
```

## 方法 3: 使用上游 Linux 内核

### 3.1 编译 RISC-V Linux 内核

```bash
# 获取 Linux 内核源码
git clone https://github.com/torvalds/linux.git
cd linux

# 配置 RISC-V
make ARCH=riscv64 defconfig

# 可选：启用更多配置选项
make ARCH=riscv64 menuconfig

# 编译
make ARCH=riscv64 -j$(nproc)

# 内核镜像位置
# arch/riscv/boot/Image
```

### 3.2 创建 initrd

```bash
# 使用 busybox 创建最小 initrd
mkdir -p /tmp/initrd
cd /tmp/initrd

# 下载并编译 busybox
git clone https://busybox.net/downloads/busybox-1.36.1.tar.bz2
cd busybox-1.36.1
make ARCH=riscv64 defconfig
make ARCH=riscv64 -j$(nproc)
make ARCH=riscv64 CONFIG_PREFIX=/tmp/initrd install

# 创建设备文件
cd /tmp/initrd
mkdir -p dev proc sys
mknod dev/null c 1 3
mknod dev/console c 5 1

# 创建 init 脚本
cat > init << 'EOF'
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev
exec /bin/sh
EOF
chmod +x init

# 打包 initrd
find . | cpio -o -H newc | xz --check=crc32 > /path/to/qemu/initrd.img
```

## 内核配置要求

### 必需的配置选项

确保内核包含以下配置：

```config
# RISC-V 架构
CONFIG_RISCV=y
CONFIG_ARCH_RV64I=y

# 文件系统支持
CONFIG_EXT4_FS=y
CONFIG_VIRTIO_BLK=y

# 网络支持
CONFIG_VIRTIO_NET=y
CONFIG_E1000=y

# 控制台支持
CONFIG_SERIAL_8250=y
CONFIG_SERIAL_OF_PLATFORM=y
```

### 检查内核配置

```bash
# 查看当前内核配置
zcat /proc/config.gz | grep -E "(EXT4|VIRTIO|SERIAL)"
```

## QEMU 启动示例

### 使用 openEuler 内核

```bash
qemu-system-riscv64 \
  -M virt \
  -m 2G \
  -smp 4 \
  -kernel Image \
  -initrd initrd.img \
  -device virtio-blk-device,drive=rootfs \
  -drive if=none,file=openeuler-24.03-SP3-riscv64-rootfs.ext4,id=rootfs \
  -append "root=/dev/vda ro console=ttyS0" \
  -nographic
```

### 使用上游内核

```bash
qemu-system-riscv64 \
  -M virt \
  -m 2G \
  -smp 4 \
  -kernel arch/riscv/boot/Image \
  -initrd initrd.img \
  -device virtio-blk-device,drive=rootfs \
  -drive if=none,file=openeuler-24.03-SP3-riscv64-rootfs.ext4,id=rootfs \
  -append "root=/dev/vda ro console=ttyS0 init=/sbin/init" \
  -nographic
```

## 常见问题

### 1. 内核版本不兼容

确保内核版本与 rootfs 的 glibc 版本兼容。openEuler 24.03 推荐使用 5.x 或 6.x 内核。

### 2. initrd 缺少必要的驱动

检查 initrd 是否包含必要的驱动：
```bash
lsinitrd initrd.img | grep virtio
```

### 3. rootfs 无法挂载

检查内核配置：
```bash
# 检查 EXT4 支持
zcat /proc/config.gz | grep EXT4_FS

# 检查 virtio 支持
zcat /proc/config.gz | grep VIRTIO_BLK
```

### 4. 启动失败: VFS: Unable to mount root fs

可能是 rootfs 设备路径错误，尝试：
- `root=/dev/vda` (virtio-blk)
- `root=/dev/virtblk0` (某些内核版本)

## 相关资源

- [openEuler 内核包仓库](https://repo.openeuler.org/openEuler-24.03/detached/YUM/SP3/standard_riscv64/Packages/)
- [Linux 内核文档](https://www.kernel.org/doc/html/latest/)
- [dracut 文档](https://man7.org/linux/man-pages/man8/dracut.8.html)