#!/bin/bash
# build_arm.sh - 构建适用于 Orin 服务器的 Docker 镜像（优化版）

# 基础镜像配置信息
# - CUDA 12.6
# - cuDNN 9.4.0 (版本号: 90400)
# - PyTorch 2.4.0
# - Torchvision 0.19.0a0+48b1edf
# - GPU: Orin (61.4 GB内存, 1个GPU)

set -e

# 检查 Docker 是否可用
echo "🔍 检查 Docker 是否可用..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker"
    exit 1
fi

# 检查本地是否已有基础镜像
echo "🔍 检查本地是否已有基础镜像 dustynv/l4t-pytorch:r36.4.0..."
if docker images | grep -q "dustynv/l4t-pytorch\s*r36.4.0"; then
    echo "✅ 发现本地基础镜像 dustynv/l4t-pytorch:r36.4.0"
else
    echo "❌ 未找到本地基础镜像 dustynv/l4t-pytorch:r36.4.0，请先确保该镜像已存在于本地"
    exit 1
fi

# 构建镜像（不使用buildx，直接使用本地镜像，避免拉取网络镜像）
echo "🚀 开始构建适用于 Orin 服务器的 Docker 镜像..."
echo "当前时间: $(date)"

docker build \
    -t video-sr-arm64:latest \
    --progress=plain \
    --no-cache \
    --pull=false \
    .

# 检查构建结果
if [ $? -eq 0 ]; then
    echo "✅ 镜像构建成功！"
    echo "镜像名称: video-sr-arm64:latest"
    
    # 显示镜像大小信息
    echo "📊 镜像大小信息:" 
    docker image ls video-sr-arm64:latest
    
    echo "💡 优化说明:"
    echo "  - 使用多阶段构建减小镜像体积"
    echo "  - 避免重复安装基础镜像中已有的CUDA 12.6、cuDNN 9.3、PyTorch等组件"
    echo "  - 仅安装必要的额外依赖包"
    
    echo "✅ 请使用 ./run_torch.sh 运行镜像"
else
    echo "❌ 镜像构建失败！"
    exit 1
fi