FROM fedora:latest

# 安装 rootfs 构建工具
RUN dnf install -y \
        dnf \
        dnf-plugins-core \
        e2fsprogs \
        util-linux \
        zstd \
        wget \
        tar \
    && dnf clean all

# 配置 openEuler-24.03-LTS-SP3 软件源
RUN printf '[openEuler-24.03-LTS-SP3]\nname=openEuler 24.03 LTS SP3\nbaseurl=https://fast-mirror.isrc.ac.cn/openeuler/openEuler-24.03-LTS-SP3/everything/riscv64/rva20/riscv64/\nenabled=1\ngpgcheck=0\n' > /etc/yum.repos.d/openEuler-24.03-LTS-SP3.repo

# 配置 openEuler-24.03-LTS-SP2 软件源
RUN printf '[openEuler-24.03-LTS-SP2]\nname=openEuler 24.03 LTS SP2\nbaseurl=https://fast-mirror.isrc.ac.cn/openeuler/openEuler-24.03-LTS-SP2/everything/riscv64/\nenabled=1\ngpgcheck=0\n' > /etc/yum.repos.d/openEuler-24.03-LTS-SP2.repo

# 配置 openRuyi RVA23 软件源
RUN printf '[openruyi-rva23]\nname=openRuyi RVA23\nbaseurl=https://boat.openruyi.cn/unstable/rva23\nenabled=1\ngpgcheck=0\n' > /etc/yum.repos.d/openruyi-rva23.repo

# 配置 openRuyi RVA20 软件源
RUN printf '[openruyi-rva20]\nname=openRuyi RVA20\nbaseurl=https://boat.openruyi.cn/unstable/rva20\nenabled=1\ngpgcheck=0\n' > /etc/yum.repos.d/openruyi-rva20.repo

# 刷新仓库缓存
RUN dnf makecache

COPY config.sh /workspace/
COPY build-rootfs.sh /workspace/
RUN chmod +x /workspace/build-rootfs.sh

WORKDIR /workspace
CMD ["/bin/bash"]
