FROM openeuler/openeuler:24.03-lts-sp2

# 安装 rootfs 构建工具
RUN dnf makecache \
    && dnf install -y \
        dnf \
        e2fsprogs \
        util-linux \
        zstd \
        wget \
        tar \
    && dnf clean all

COPY base.list /workspace/
COPY build-rootfs.sh /workspace/
RUN chmod +x /workspace/build-rootfs.sh

WORKDIR /workspace
CMD ["/bin/bash"]
