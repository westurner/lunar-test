# Dockerfile for lunarengine devcontainer

# FROM ubuntu:22.04
# FROM ubuntu:24.04
FROM ubuntu:latest

WORKDIR /workspace

# Install build dependencies
RUN --mount=type=cache,target=/var/cache/apt,id=apt-cache \
    --mount=type=cache,target=/var/lib/apt,id=apt-lib \
    apt-get update && apt-get install -y \
    # Core build dependencies for librebox
    bash-completion \
    build-essential \
    cmake \
    git \
    pkg-config \
    curl \
    # X11 and input
    libx11-dev \
    libxi-dev \
    libxrandr-dev \
    libxinerama-dev \
    libxcursor-dev \
    libxext-dev \
    libxft-dev \
    libxfixes-dev \
    libxrender-dev \
    libxss-dev \
    libxxf86vm-dev \
    # Audio
    libasound2-dev \
    libpulse-dev \
    # Device management
    libudev-dev \
    # Software rendering fallback
    libgl1-mesa-dev \
    # Python (for build scripts/tests)
    python3 \
    python3-pip \
    # Additional raylib dependencies
    libopenal-dev \
    libglfw3-dev \
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    libvorbis-dev \
    libogg-dev \
    libwebp-dev \
    # Uncomment if you want system Lua (luau uses its own VM)
    # liblua5.3-dev \
    # Fuzz/test dependencies (optional, for luau fuzzing/tests)
    protobuf-compiler \
    libprotobuf-dev \
    ninja-build \
    lcov \
    doxygen \
    && rm -rf /var/lib/apt/lists/*

# Copy workspace (if needed, but devcontainer mounts it)
# COPY . /workspace

# Default user
#USER ubuntu
#USER 1000:1000

# Default command
CMD ["bash --login"]
