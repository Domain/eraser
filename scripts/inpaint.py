#!/usr/bin/env python3
"""
简单的笔迹检测与抹除脚本（示例实现，需根据样本调整参数）

用法:
    python3 scripts/inpaint.py input_image output_image

实现思路（示例）:
- 将图像转为灰度并做自适应阈值，得到黑白图。
- 使用较大的闭运算（morphology close）提取较粗的印刷/打印文本区域（或背景块）。
- 将闭运算结果从阈值图中减去，保留细线/连笔（候选手写）。
- 清理小连通域 / 过大的连通域（可通过面积过滤）。
- 使用 cv2.inpaint 对原图进行修复，mask 为检测到的手写区域。

注意: 该算法对不同纸张、印刷/笔迹颜色、扫描质量差异较敏感。可以替换为更复杂的分割模型（如 U-Net）提高效果。
"""
import cv2
import numpy as np
import sys

def ensure_args():
    if len(sys.argv) < 3:
        print("Usage: python3 scripts/inpaint.py input_image output_image")
        sys.exit(1)

def detect_handwriting_mask(img_gray):
    # 自适应阈值，得到二值图（黑底白字或白底黑字视具体图像可能需取反）
    th = cv2.adaptiveThreshold(img_gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                               cv2.THRESH_BINARY_INV, 25, 10)
    # 形态学闭操作：去除细小间隙，把印刷字符连成块（kernel 大小可调整）
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (15, 3))
    closed = cv2.morphologyEx(th, cv2.MORPH_CLOSE, kernel, iterations=1)

    # handwriting candidates = threshold - closed (保留较细的笔迹)
    hand_candidates = cv2.subtract(th, closed)

    # 进一步用开操作去噪
    kernel2 = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3,3))
    hand_candidates = cv2.morphologyEx(hand_candidates, cv2.MORPH_OPEN, kernel2, iterations=1)

    # 连通域过滤（去掉太小或太大的区域）
    contours, _ = cv2.findContours(hand_candidates, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    mask = np.zeros_like(hand_candidates)
    h, w = hand_candidates.shape
    img_area = h * w
    for cnt in contours:
        area = cv2.contourArea(cnt)
        # 保留面积在一定范围内的区域（阈值需根据样本调整）
        if area > 10 and area < img_area * 0.05:
            cv2.drawContours(mask, [cnt], -1, 255, -1)
    # 可做一次膨胀以确保笔迹连通更好，便于 inpaint
    kernel3 = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5,5))
    mask = cv2.dilate(mask, kernel3, iterations=1)
    return mask

def main():
    ensure_args()
    inp = sys.argv[1]
    out = sys.argv[2]

    img = cv2.imdecode(np.fromfile(inp, dtype=np.uint8), cv2.IMREAD_COLOR)
    if img is None:
        print("Failed to read image:", inp)
        sys.exit(2)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    mask = detect_handwriting_mask(gray)

    # 如果 mask 太小（没检测到），直接保存原图（或微调）
    if cv2.countNonZero(mask) < 10:
        # 保存原图
        cv2.imencode('.png', img)[1].tofile(out)
        print("No handwriting detected, saved original.")
        return

    # 使用 inpaint 修复
    inpainted = cv2.inpaint(img, mask, 3, cv2.INPAINT_TELEA)

    # 保存结果（使用 imencode + tofile 以支持包含中文路径）
    ext = out.split('.')[-1]
    cv2.imencode('.' + ext, inpainted)[1].tofile(out)
    print("Inpainted saved to", out)

if __name__ == "__main__":
    main()