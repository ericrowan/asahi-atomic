# 1. SETUP BUILD CONTEXT
FROM scratch AS ctx
COPY build_files /

# 2. DEFINE BASE IMAGE (Fedora 41/Bluefin Stable)
FROM ghcr.io/ublue-os/bluefin:stable

# 3. THE ASAHI KERNEL SWAP (The Core Mutation)
# We do this early to ensure the kernel is correct before other layers
RUN curl -o /etc/yum.repos.d/asahi.repo https://asahi.fedoraproject.org/aarch64/asahi.repo && \
    dnf remove -y kernel kernel-core kernel-modules kernel-modules-core && \
    dnf install -y kernel-asahi asahi-firmware asahi-bless asahi-config \
                   m1n1 u-boot asahi-audio speakersafetyd asahi-nvram && \
    dnf clean all

# 4. EXECUTE BUILD SCRIPTS (Packages & Config)
# This runs the scripts inside build_files/
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

# 5. FINAL LINTING
RUN bootc container lint