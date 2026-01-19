module ocr;

import std.process;
import std.string;

/// 调用 tesseract 命令行并返回全部 OCR 文本（stdout）
/// 需要确保系统安装了 tesseract，且可执行
string runTesseract(string imagePath, string lang = "eng")
{
    // 调用 tesseract <image> stdout -l <lang>
    auto cmd = ["tesseract", imagePath, "stdout", "-l", lang];
    auto res = execute(cmd);
    if (res.status != 0)
    {
        // 如果失败，返回空字符串；调用方会将文件归入 unknown
        return "";
    }
    return res.output;
}