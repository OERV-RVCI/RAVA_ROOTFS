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
RUN cat > /etc/yum.repos.d/openEuler-24.03-LTS-SP3.repo << 'EOF'
[openEuler-24.03-LTS-SP3]
name=openEuler 24.03 LTS SP3
baseurl=https://fast-mirror.isrc.ac.cn/openeuler/openEuler-24.03-LTS-SP3/everything/riscv64/
enabled=1
gpgcheck=0
EOF

# 配置 openEuler-24.03-LTS-SP2 软件源
RUN cat > /etc/yum.repos.d/openEuler-24.03-LTS-SP2.repo << 'EOF'
[openEuler-24.03-LTS-SP2]
name=openEuler 24.03 LTS SP2
baseurl=https://fast-mirror.isrc.ac.cn/openeuler/openEuler-24.03-LTS-SP2/everything/riscv64/
enabled=1
gpgcheck=0
EOF

# 配置 openRuyi RVA23 软件源
RUN cat > /etc/yum.repos.d/openruyi-rva23.repo << 'EOF'
[openruyi-rva23]
name=openRuyi RVA23
baseurl=https://boat.openruyi.cn/unstable/rva23
enabled=1
gpgcheck=0
EOF

# 配置 openRuyi RVA20 软件源
RUN cat > /etc/yum.repos.d/openruyi-rva20.repo << 'EOF'
[openruyi-rva20]
name=openRuyi RVA20
baseurl=https://boat.openruyi.cn/unstable/rva20
enabled=1
gpgcheck=0
EOF

COPY config.sh /workspace/
COPY build-rootfs.sh /workspace/
RUN chmod +x /workspace/build-rootfs.sh

WORKDIR /workspace
CMD ["/bin/bash"]
