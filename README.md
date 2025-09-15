# 视频超分辨率 (Video Super-Resolution) 

## 项目简介
本项目基于ARM64架构的NVIDIA Orin平台，使用Docker容器化部署，实现视频超分辨率处理。项目采用MMagic框架和[BasicVSR++](https://github.com/OpenMMLab/MMEditing/blob/main/configs/restorers/basicvsr_plusplus/)模型（来自OpenMMLab），能够高效提升视频画质。

## 1. 设备和环境准备

### 硬件要求
- **处理器**: ARM64架构处理器 (如NVIDIA Orin系列)
- **GPU**: NVIDIA GPU (支持CUDA)
- **存储空间**: 至少15GB空闲空间

### 软件要求
- **操作系统**: Linux (支持Docker)
- **Docker**: 20.10或更高版本
- **NVIDIA Container Toolkit (可选)**: 用于GPU加速

### 预安装组件
Docker镜像已预装以下组件：
- CUDA 12.6
- cuDNN 9.4.0
- PyTorch 2.4.0
- Torchvision 0.19.0a0+48b1edf
- Python 3.10
- MMCV 2.1.0
- MMagic 1.2.0

## 2. 宿主机目录结构

项目采用以下目录结构组织文件和数据：

```
├── Dockerfile             # Docker镜像构建文件
├── build_torch.sh         # 镜像构建脚本
├── check_env.sh           # 容器环境检查运行脚本
├── check_torch.py         # PyTorch环境检查脚本
├── video-sr.py            # 视频超分辨率主程序
└── data/
    ├── input/             # 存放输入视频文件
    │   └── test1.mp4      # 测试视频示例
    └── output/            # 存放处理后的文件
        └── test1_sr.mp4   # 超分辨率处理后的视频示例
        └── test1_psnr.txt # PSNR值示例
```

## 3. 镜像构建与使用

### 构建镜像
使用项目提供的构建脚本创建Docker镜像：

```bash
chmod +x build_torch.sh
./build_torch.sh
```

> **注意**: 构建时需要确保本地已存在 [`dustynv/l4t-pytorch:r36.4.0`](https://hub.docker.com/layers/dustynv/l4t-pytorch/r36.4.0/images/sha256-a05c85def9139c21014546451d3baab44052d7cabe854d937f163390bfd5201b) 基础镜像

### 拉取和使用镜像

#### NVIDIA Container Toolkit可用时

```bash
sudo docker run -it --rm --gpus all \
  -v $(pwd)/data:/data \
  video-sr-arm64:latest \
  python3 video-sr.py --input <输入视频路径> --output <输出视频路径> --max_seq_len 10
```

#### NVIDIA Container Toolkit不可用时

```bash
sudo docker run -it --rm --runtime=nvidia \
  -v $(pwd)/data:/data \
  video-sr-arm64:latest \
  python3 video-sr.py --input <输入视频路径> --output <输出视频路径> --max_seq_len <序列长度>
```

> **说明**: 序列长度参数默认为10，可根据需要调整

### 示例使用

处理data/input目录下的test1.mp4视频，输出到data/output目录：

```bash
sudo docker run -it --rm --gpus all \
  -v $(pwd)/data:/data \
  video-sr-arm64:latest \
  python3 video-sr.py --input /data/input/test1.mp4 --output /data/output/test1_sr.mp4 --max_seq_len 20
```

## 4. 功能特点

- **预封装模型**: 镜像内置了预下载的模型文件，无需运行时重复下载
- **GPU加速**: 充分利用NVIDIA GPU进行高性能视频处理
- **支持自定义参数**: 可调整序列长度等参数优化处理效果
- **自动计算PSNR**: 处理后自动计算并输出视频质量提升指标

## 5. 注意事项

1. 确保Docker服务正常运行且用户具有sudo权限
2. 首次运行时，会先联网下载SPyNet和basicvsr_plusplus的models
3. 处理大视频文件时，确保系统有足够的内存和磁盘空间
4. 如需修改或扩展功能，请参考`video-sr.py`文件中的代码实现
