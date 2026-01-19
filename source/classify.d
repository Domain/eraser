module classify;

import std.string;
import std.algorithm;
import std.uni;

/// 根据 OCR 的第一行文本生成一个安全的文件夹名（去除非法字符、截断等）
string titleToFolder(string title)
{
    // 简单清洗：去首尾空格，替换连续空白为单个下划线，去除文件名非法字符
    auto t = title.strip();
    // 保留字母数字和中文，其他替换为 '_'
    string out;
    foreach (c; t)
    {
        // 中文范围的大致判断：如果是字母或数字或常见中文字符范围则保留
        ubyte[] buf = cast(ubyte[])(c.toUTF8());
        if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9'))
        {
            out ~= c;
        }
        else
        {
            // 尝试检测是否为常见中文字符（粗略判断）
            // 将 UTF-8 字节长度 > 1 的视为中文/其他多字节字符，保留
            if (buf.length > 1)
                out ~= c;
            else
                out ~= '_';
        }
    }
    // 多个下划线合并
    while (out.find("__") != -1)
        out = out.replace("__", "_");
    // 限长
    if (out.length > 80) out = out[0 .. 80];
    // 去除首尾下划线
    out = out.strip("_");
    if (out.length == 0) out = "untitled";
    return out;
}