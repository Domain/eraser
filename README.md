# 试卷笔迹抹除与自动归类（主控用 D，图像处理用 OpenCV-Python）

说明（中文）

功能：
- 对输入目录中的扫描/拍照试卷图片进行“笔迹抹除”（inpainting），生成干净的试卷图片。
- 对去笔迹后的图片使用 Tesseract OCR 自动识别文本，提取第一行作为试卷标题候选。
- 根据识别到的标题自动将图片归类到输出目录下对应的子目录（如果无法识别，则放到 `unknown/`）。

实现思路：
- D 程序作为主控制器（DUB 项目），负责遍历文件、调用 inpaint 脚本与 Tesseract、依据 OCR 输出分类与保存。
- inpaint 使用 Python + OpenCV（cv2），便于快速实验和调整（可以后续替换为纯 D + OpenCV 绑定实现）。

先决条件：
- D 编译器与 DUB（https://dlang.org/getting_started.html）
- Python 3（>=3.7）
- pip 包：opencv-python, numpy
  安装：pip3 install opencv-python numpy
- Tesseract OCR（命令行程序）
  - Ubuntu/Debian: `sudo apt install tesseract-ocr`
  - macOS (brew): `brew install tesseract`
  - 若需要中文识别，安装中文语言包（Ubuntu: `sudo apt install tesseract-ocr-chi-sim`）
- 可选：优化图片质量（去噪、校正透视）可先用其他工具预处理。

如何运行：
1. 准备输入目录（例如 `data/in/`），放入若干 `.jpg`/`.png`/`.tif` 文件。
2. 确保 tesseract 可在命令行调用（`tesseract --version`）。
3. 确保 Python 与依赖库安装。
4. 构建并运行：
   - 使用 DUB 构建：`dub build`
   - 或直接运行：`dub run -- input_dir output_dir`
   - 示例：`dub run -- data/in data/out`
5. 运行后，输出目录（`data/out`）会包含：
   - cleaned/ （去笔迹后的图像）
   - categorized/<title>/ （按识别到的标题分类移动源文件或结果文件）
   - unknown/ （无法识别标题的）

可调参数与改进方向：
- `scripts/inpaint.py` 中的阈值、Morph kernel 大小和过滤面积可根据试卷风格调整以提高笔迹检测准确性。
- 可将 OCR 用更强的中文模型或后处理（中文分词/正则）提取标准化标题。
- 若想实现纯 D + OpenCV，可考虑使用 BindBC 或其他 OpenCV D 绑定，替换 Python 脚本中的图像处理部分。

日志与调试：
- 程序会打印每张图片的处理状态、OCR 原始文本和归类结果。若出错，会在控制台输出。

许可证：
- 你可以自由修改并按需商用本示例代码.