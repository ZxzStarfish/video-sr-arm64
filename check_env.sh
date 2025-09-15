#!/bin/bash
# run_torch.sh - 运行适用于 Orin 服务器的 Docker 镜像并访问 GPU（优化版）

# 基础镜像配置信息
# - CUDA 12.6
# - cuDNN 9.4.0 (版本号: 90400)
# - PyTorch 2.4.0
# - Torchvision 0.19.0a0+48b1edf
# - GPU: Orin (61.4 GB内存, 1个GPU)

set -e

echo "🚀 启动优化后的 Docker 容器并运行 check_torch.py..."
echo "当前时间: $(date)"
echo "当前基础镜像：dustynv/l4t-pytorch:r36.4.0 (CUDA 12.6, cuDNN 9.3, Ubuntu 22.04)"

# 镜像名称
IMAGE_NAME="video-sr-arm64"

# 检查 Docker 是否可用
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker"
    exit 1
fi

# 检查镜像是否存在
if ! docker images | grep -q "$IMAGE_NAME"; then
    echo "❌ $IMAGE_NAME 镜像不存在，需要使用sudo ./build_torch.sh 构建镜像"
    # ./build_torch.sh
    # if [ $? -ne 0 ]; then
    #     echo "❌ 镜像构建失败！"
    #     exit 1
    # fi
fi

# 检查 NVIDIA Container Toolkit 是否可用
echo "🔍 检查 NVIDIA Container Toolkit 是否可用..."
if ! docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu22.04 nvidia-smi &> /dev/null; then
    echo "⚠️ NVIDIA Container Toolkit 可能未正确安装，尝试使用 --runtime=nvidia..."
    GPU_FLAG="--runtime=nvidia"
else
    GPU_FLAG="--gpus all"
fi

# 运行 Docker 容器，确保 GPU 可访问
echo "📊 运行环境检查脚本 check_torch.py..."
docker run --rm \
    $GPU_FLAG \
    --shm-size=8g \
    --ulimit memlock=-1 \
    --ulimit stack=67108864 \
    -e NVIDIA_VISIBLE_DEVICES=all \
    -e NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    --pull=missing \
    $IMAGE_NAME

echo "✅ 环境检查完成！"
echo "💡 提示：如果需要交互式运行容器，可以使用以下命令："
echo "  docker run -it --rm $GPU_FLAG --pull=missing video-sr-arm64:latest /bin/bash"
echo "💡 在容器内，您可以使用以下命令验证 PyTorch 和 GPU 环境："
echo "  - python3 -c \"import torch; print('PyTorch 版本:', torch.__version__); print('CUDA 可用:', torch.cuda.is_available())\""
echo "  - python3 -c \"import torchvision; print('Torchvision 版本:', torchvision.__version__)\""
echo "  - python3 -c \"print('CUDA 版本:', torch.version.cuda); print('cuDNN 版本:', torch.backends.cudnn.version())\""
echo "  - python3 check_torch.py"
# sudo docker run -it --rm --runtime=nvidia -v $(pwd)/data:/data video-sr-arm64:latest python3 video-sr.py --input /data/test1.mp4 --output /data/output1.mp4
