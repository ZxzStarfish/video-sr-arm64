# 使用 NVIDIA L4T PyTorch 作为基础镜像（适用于 Orin 服务器的 ARM 架构）
# 该镜像已预装：CUDA 12.6, cuDNN 9.4.0, PyTorch 2.4.0, Torchvision 0.19.0a0+48b1edf, Python
# 重要提示：构建时请使用 docker build --pull=false 参数，避免尝试从网络拉取基础镜像

# ====== 第一阶段：基础镜像和文件准备 ======
FROM dustynv/l4t-pytorch:r36.4.0 AS base

# 维护者信息
LABEL maintainer="Zhang Xingzhe"

# 设置工作目录
WORKDIR /app

# 创建PyTorch模型缓存目录
RUN mkdir -p /root/.cache/torch/hub/checkpoints

# 复制环境配置文件和启动脚本到基础阶段
# COPY requirements.txt .
COPY check_torch.py .
COPY video-sr.py .

# 直接从网络下载模型文件到Docker镜像中（不依赖本地文件）
RUN wget -q -O /root/.cache/torch/hub/checkpoints/spynet_20210409-c6c1bd09.pth https://download.openmmlab.com/mmediting/restorers/basicvsr/spynet_20210409-c6c1bd09.pth
RUN wget -q -O /root/.cache/torch/hub/checkpoints/basicvsr_plusplus_c64n7_8x1_600k_reds4_20210217-db622b2f.pth https://download.openmmlab.com/mmediting/restorers/basicvsr_plusplus/basicvsr_plusplus_c64n7_8x1_600k_reds4_20210217-db622b2f.pth

# ====== 第二阶段：构建阶段 - 安装依赖和编译 ======
FROM dustynv/l4t-pytorch:r36.4.0 AS builder

WORKDIR /app

# 单独安装mmagic和mmcv，让它们自动选择适合当前ARM架构的版本
# 注意：安装mmcv时会自动安装mmengine作为其依赖项
# 针对Orin服务器ARM64架构的优化安装命令
RUN echo "单独安装mm系列库，自动选择适合ARM架构的版本..."
# 1. 安装编译依赖（mmcv可能需要从源码编译）
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc g++ make cmake \
    libopenblas-dev liblapack-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. 更新pip并配置特定于Orin的环境变量
RUN pip install \
    --index-url https://pypi.tuna.tsinghua.edu.cn/simple \
    --trusted-host pypi.tuna.tsinghua.edu.cn \
    --upgrade pip
# 其他可选镜像源（注释中保留作为参考）
# --index-url https://mirrors.aliyun.com/pypi/simple/
# --index-url https://pypi.org/simple
# 设置编译优化环境变量，适合Orin处理器
ENV MMCV_WITH_OPS=1 \
    FORCE_CUDA=1 \
    CUDA_HOME=/usr/local/cuda \
    TORCH_CUDA_ARCH_LIST="8.7"

# 3. 针对Orin服务器优化的pip安装命令
# 安装openmim，这是mm系列库的官方安装工具
RUN pip install \
    --index-url https://pypi.tuna.tsinghua.edu.cn/simple \
    --trusted-host pypi.tuna.tsinghua.edu.cn \
    --timeout 300 \
    openmim
# 其他可选镜像源
# --extra-index-url https://mirrors.aliyun.com/pypi/simple/
# --extra-index-url https://pypi.org/simple
# --trusted-host mirrors.aliyun.com
# --trusted-host pypi.org
# --trusted-host files.pythonhosted.org

# 使用openmim安装mmcv-full（支持GPU加速）和mmagic
# openmim会自动处理依赖关系和CUDA优化
RUN mim install \
    --index https://pypi.tuna.tsinghua.edu.cn/simple \
    mmcv==2.1.0 \
    mmengine \
    mmagic || \
    # 如果失败，尝试从源码编译安装，增加并行度
    mim install --no-cache-dir \
    --index https://pypi.tuna.tsinghua.edu.cn/simple \
    --no-binary :all: \
    -v \
    mmcv==2.1.0 \
    mmengine \
    mmagic

# 安装项目依赖（避免重新安装CUDA、cuDNN、Python、PyTorch）
# 使用相同的pip源配置以保持一致性
# RUN pip install --no-cache-dir \
#     --index-url https://pypi.tuna.tsinghua.edu.cn/simple \
#     --trusted-host pypi.tuna.tsinghua.edu.cn \
#     --timeout 300 \
#     -r requirements.txt && \
#     rm requirements.txt
RUN pip install --no-cache-dir \
    --index-url https://pypi.tuna.tsinghua.edu.cn/simple \
    --trusted-host pypi.tuna.tsinghua.edu.cn \
    --timeout 300 \
    albumentations \
    albucore \
    numpy==1.26.4 \
    opencv-python==4.9.0.80 \
    opencv-python-headless==4.9.0.80 \
    huggingface-hub==0.19.4 \
    diffusers==0.24.0 \
    transformers==4.35.2 \
    pillow \
    tensorboard
# ====== 第三阶段：最终运行时镜像 ======
FROM dustynv/l4t-pytorch:r36.4.0 AS runtime

WORKDIR /app

# 从builder阶段复制已安装的Python依赖包
# 注意：基础镜像使用Python 3.10，确保依赖路径正确
COPY --from=builder /usr/local/lib/python3.10/dist-packages /usr/local/lib/python3.10/dist-packages

# 从base阶段复制启动脚本、应用程序文件和预下载的模型文件
COPY --from=base /app/check_torch.py .
COPY --from=base /app/video-sr.py .
COPY --from=base /root/.cache/torch/hub/checkpoints /root/.cache/torch/hub/checkpoints

# 设置环境变量以启用 GPU 访问
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# 设置默认命令，运行检查脚本
# 注意：容器中使用python3命令而不是python
CMD ["python3", "check_torch.py"]