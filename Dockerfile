FROM openeuler/openeuler:24.03-lts-sp2

# 安装制作 rootfs 所需的工具
RUN dnf makecache \
    && dnf install -y \
        dnf-plugins-core \
        qemu-img \
        dosfstools \
        e2fsprogs \
        util-linux \
        kpartx \
        rsync \
        xz \
        zstd \
    && dnf clean all

# 复制包列表和构建脚本
COPY base.list /workspace/
COPY build-rootfs.sh /workspace/

# 给脚本执行权限
RUN chmod +x /workspace/build-rootfs.sh

# 设置工作目录
WORKDIR /workspace

# 默认不执行任何操作，由外部调用
CMD ["/bin/bash"]