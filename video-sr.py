import os
import torch
import cv2
import numpy as np
import argparse
from mmagic.apis import MMagicInferencer
from mmengine import mkdir_or_exist

def calculate_psnr(video1_path, video2_path):
    """
    计算两个视频之间的平均 PSNR 值

    参数:
    video1_path (str): 第一个视频文件路径
    video2_path (str): 第二个视频文件路径

    返回:
    float: 平均 PSNR 值
    """
    # 打开视频文件
    cap1 = cv2.VideoCapture(video1_path)
    cap2 = cv2.VideoCapture(video2_path)

    # 检查视频是否成功打开
    if not cap1.isOpened() or not cap2.isOpened():
        print("  ❌无法打开视频文件")
        return None

    # 获取视频信息
    fps1 = cap1.get(cv2.CAP_PROP_FPS)
    fps2 = cap2.get(cv2.CAP_PROP_FPS)
    frame_count1 = int(cap1.get(cv2.CAP_PROP_FRAME_COUNT))
    frame_count2 = int(cap2.get(cv2.CAP_PROP_FRAME_COUNT))

    # 检查视频帧率是否匹配
    # if fps1 != fps2:
    #     print("警告: 视频帧率不匹配")
    #     print(f"video1 帧率 {fps1}, {frame_count1} 帧")
    #     print(f"video2 帧率 {fps2}, {frame_count2} 帧")

    # 以帧数较少的视频为准
    min_frame_count = min(frame_count1, frame_count2)

    total_psnr = 0.0
    valid_frames = 0

    # print(f"  开始计算 PSNR，共 {min_frame_count} 帧...")

    for i in range(min_frame_count):
        # 读取帧
        ret1, frame1 = cap1.read()
        ret2, frame2 = cap2.read()

        if not ret1 or not ret2:
            print(f"  ⚠️在帧 {i} 处读取失败")
            break

        # 确保帧尺寸相同
        if frame1.shape != frame2.shape:
            frame2 = cv2.resize(frame2, (frame1.shape[1], frame1.shape[0]))

        # 转换颜色空间为YUV，只计算Y分量(亮度)的PSNR
        frame1_yuv = cv2.cvtColor(frame1, cv2.COLOR_BGR2YUV)
        frame2_yuv = cv2.cvtColor(frame2, cv2.COLOR_BGR2YUV)

        # 计算Y分量的MSE
        mse = np.mean((frame1_yuv[:, :, 0] - frame2_yuv[:, :, 0]) ** 2)

        # 避免除以零
        if mse == 0:
            psnr = 100  # 无限大PSNR，设为100
        else:
            psnr = 20 * np.log10(255.0 / np.sqrt(mse))

        total_psnr += psnr
        valid_frames += 1

        # 每处理20帧打印一次进度
        # if (i + 1) % 20 == 0:
        #     print(f"已处理 {i + 1} 帧，当前平均 PSNR: {total_psnr / valid_frames:.2f} dB")

    # 释放视频捕获对象
    cap1.release()
    cap2.release()

    if valid_frames == 0:
        print("  ⚠️未能成功处理任何帧")
        return None

    average_psnr = total_psnr / valid_frames

    # 输出
    if average_psnr is not None:
        print(f"  增强前后视频的平均 PSNR 值为 {average_psnr:.2f} dB")
    else:
        print("  ❌PSNR计算失败")

    return average_psnr

def SR(video_dir, result_video_dir, device, max_seq_len):
    """
    视频超分辨率增强

    参数:
    video_dir: 输入视频目录
    result_video_dir: 输出视频目录
    device: CPU or GPU(cuda)
    max_seq_len: 模型一次处理的帧数, 值越大占用的GPU越多
    """
    # 创建实例
    print(f"  创建实例...")
    editor = MMagicInferencer(model_name='basicvsr_pp', device=device)
    editor.inferencer.inferencer.extra_parameters['max_seq_len'] = max_seq_len

    # 推理前清理
    # print(f"清理cuda...")
    torch.cuda.empty_cache()
    print(f"  执行推理...")
    # 执行推理
    editor.infer(video=video_dir, result_out_dir=result_video_dir)
    # 推理后清理
    torch.cuda.empty_cache()


def main():
    parser = argparse.ArgumentParser(description='Video Super-Resolution with PSNR Calculation')
    parser.add_argument('--input', type=str, required=True, help='Path to input video')
    parser.add_argument('--output', type=str, required=True, help='Path to output video')
    parser.add_argument('--max_seq_len', type=int, default=10, help='Max sequence length for BasicVSR++')

    args = parser.parse_args()

    video_dir = args.input
    result_video_dir = args.output
    max_seq_len = args.max_seq_len

    # 自动检测设备
    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    print(f"使用设备: {device}")

    # 检查原始视频是否存在
    if not os.path.exists(video_dir):
        print(f"❌原始视频文件不存在: {video_dir}")
        exit(1)

    # 创建输出目录
    mkdir_or_exist(os.path.dirname(result_video_dir))

    # 超分辨率增强
    print("开始视频超分辨率处理...")
    SR(video_dir, result_video_dir, device, max_seq_len)

    # 计算PSNR
    print("计算PSNR...")
    psnr_value = calculate_psnr(video_dir, result_video_dir)

    # 输出PSNR值到文件
    psnr_file = f"{result_video_dir}_psnr.txt"
    with open(psnr_file, 'w') as f:
        f.write(f"{psnr_value:.2f}")

    print(f"\n✅处理完成! PSNR值已保存到: {psnr_file}")
    print(f"✅增强后的视频保存到: {result_video_dir}")


if __name__ == "__main__":
    main()