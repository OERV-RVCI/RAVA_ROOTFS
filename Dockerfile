FROM hub.oepkgs.net/oerv-ci/openeuler:24.03-lts-sp1

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
        systemd \
    && dnf clean all

# 设置工作目录
WORKDIR /workspace

# 复制构建脚本和包列表
COPY build-rootfs.sh /workspace/
COPY base.list /workspace/

# 给脚本执行权限
RUN chmod +x /workspace/build-rootfs.sh

# 默认执行构建
ENTRYPOINT ["/workspace/build-rootfs.sh"]