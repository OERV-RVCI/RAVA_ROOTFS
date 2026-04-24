# openEuler RISC-V Rootfs 构建详解

## 架构说明

本项目使用 Docker + DNF 的方式构建 openEuler RISC-V rootfs。

```
┌─────────────────────────────────────────┐
│         GitHub Actions / 本地           │
│  (触发流水线)                              │
└──────────────────┬──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│       Docker BuildX (构建镜像)           │
│  - openEuler 基础镜像                     │
│  - 安装构建工具                          │
│  - 复制构建脚本                          │
└──────────────────┬──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│     Docker 容器运行 (构建 rootfs)        │
│  - 创建基本目录结构                       │
│  - 配置软件源                             │
│  - 安装软件包                             │
│  - 配置系统服务                           │
│  - 创建 ext4 镜像                         │
│  - 打包 tar.xz                            │
└──────────────────┬──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│           输出产物                        │
│  - *.ext4 (ext4 文件系统)                 │
│  - *.tar.xz (压缩包)                       │
└─────────────────────────────────────────┘
```

## 构建脚本详解

### build-rootfs.sh 主要流程

1. **准备阶段**
   - 清理旧文件
   - 创建 rootfs 目录
   - 配置 openEuler 软件源

2. **创建目录结构**
   - 创建 FHS 标准目录
   - 创建设备文件 (/dev/console, /dev/null 等)

3. **安装软件包**
   - 使用 DNF 安装 Minimal Install 包组
   - 包含: kernel, systemd, NetworkManager, openssh 等

4. **系统配置**
   - 配置 fstab
   - 配置 hostname
   - 配置网络 (DHCP)
   - 配置 SSH
   - 设置 root 密码

5. **生成镜像**
   - 创建 ext4 文件系统
   - 复制 rootfs 内容
   - 打包 tar.xz

## 软件包说明

### 核心包组

- **kernel**: Linux 内核
- **systemd**: 系统和服务管理器
- **NetworkManager**: 网络管理
- **openssh-server**: SSH 服务器
- **bash**: Shell 环境

### 可选添加

```bash
# 在 build-rootfs.sh 的 dnf install 中添加
vim              # 文本编辑器
git              # 版本控制
docker           # 容器支持
```

## 常见问题

### 1. 构建失败: "Failed to download metadata"

**原因**: 网络问题或软件源不可用

**解决**:
```bash
# 替换为其他镜像源
REPO_URL="https://mirrors.huaweicloud.com/openeuler/openEuler-24.03/detached/YUM/SP3/standard_riscv64/"
```

### 2. ext4 镜像无法挂载

**原因**: 镜像损坏或格式错误

**解决**:
```bash
# 检查镜像
fsck.ext4 -f openeuler-24.03-SP3-riscv64-rootfs.ext4

# 重新创建
dd if=/dev/zero of=image.ext4 bs=1M count=2048
mkfs.ext4 -F image.ext4
```

### 3. QEMU 启动失败: "No such device"

**原因**: 内核与 rootfs 不匹配

**解决**: 确保内核版本与 openEuler 24.03 SP3 兼容

## 性能优化

### 减少镜像大小

```bash
# 在 build-rootfs.sh 中
# 清理不需要的语言包
rm -rf ${ROOTFS_DIR}/usr/share/locale/*

# 清理文档
rm -rf ${ROOTFS_DIR}/usr/share/doc/*

# 清理 man pages
rm -rf ${ROOTFS_DIR}/usr/share/man/*
```

### 加速构建

```bash
# 使用本地镜像缓存
docker run --rm --privileged \
    -v $(pwd)/output:/workspace \
    -v $(pwd)/dnf-cache:/var/cache/dnf \
    rootfs-builder:latest
```

## 安全加固

### 更改默认密码

```bash
# 在 build-rootfs.sh 中修改
echo "root:your_new_password" | chroot "${ROOTFS_DIR}" chpasswd
```

### 禁用 SSH 密码登录

```bash
# 在 /etc/ssh/sshd_config 中
PasswordAuthentication no
PubkeyAuthentication yes
```

### 更新系统

```bash
# 构建前更新所有包
dnf install -y --installroot="${ROOTFS_DIR}" update
```

## 集成到 CI/CD

### Jenkins 示例

```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh './local-build.sh'
            }
        }
        stage('Archive') {
            steps {
                archiveArtifacts artifacts: 'output/*.ext4', fingerprint: true
                archiveArtifacts artifacts: 'output/*.tar.xz', fingerprint: true
            }
        }
    }
}
```

## 参考资源

- [openEuler 官方文档](https://www.openeuler.org/zh/)
- [openEuler RISC-V](https://www.openeuler.org/zh/architecture/riscv/)
- [DNF 文档](https://dnf.readthedocs.io/)
- [systemd 文档](https://systemd.io/)